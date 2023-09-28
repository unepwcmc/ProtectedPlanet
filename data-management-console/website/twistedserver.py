# Set of main API points supported by the Data Management Service.  As the code reorganizes (particularly around
# installation of specific apps), some of these calls may change e.g. the series of install-<appname> will become
# install_app [POST] where the body of the message is the json for that application

from twisted.internet import reactor, defer
from twisted.web import server, resource
import base64
from website.maininterface import *

mappings = {
    '/': return_home_page,
    '/index': return_home_page,
    '/clear_database': clear_database,
    '/country_metrics': country_metrics,
    '/create_foundation': create_foundation,
    '/create_reference_data': create_reference_data,
    '/define_adhoc_query': define_adhoc_query,
    '/fire_query': fire_query,
    '/install_demo': install_demo,
    '/install_green_list': install_green_list,
    '/install_icca': install_icca,
    '/install_pame': install_pame,
    '/install_wdpa': install_wdpa,
    '/load_quarantine_data': load_quarantine_data,
    '/load_quarantine_data_action': load_quarantine_data_to_staging,
    '/metrics_for_countries': metrics_for_countries,
    '/south_africa_metrics': south_africa_metrics,
    '/uninstall_demo': uninstall_demo,
    '/uninstall_foundation': uninstall_foundation,
    '/uninstall_green_list': uninstall_green_list,
    '/uninstall_icca': uninstall_icca,
    '/uninstall_pame': uninstall_pame,
    '/uninstall_reference_data': uninstall_reference_data,
    '/uninstall_wdpa': uninstall_wdpa,
    '/view_metadata': view_metadata
}


class DummyServer(resource.Resource):
    isLeaf = True

    def returnContent(self, deferred, request, msg):
        print(f"Finishing request to '{request.uri}'")
        request.write(msg)
        request.finish()

    def cancelAnswer(self, err, request, delayedTask):
        print("Cancelling request to '%s': %s" % \
              (request.uri, err.getErrorMessage()))
        delayedTask.cancel()

    def render_GET(self, request):
        print("Received request for '%s'" % request.uri)
        if request.uri == '/delayed':
            print("Delaying answer for '/delayed'")
            d = defer.Deferred()
            delayedTask = reactor.callLater(60, self.returnContent, d,
                                            request, "Hello, delayed world!")
            request.notifyFinish().addErrback(self.cancelAnswer,
                                              request, delayedTask)
            return server.NOT_DONE_YET
        elif request.uri == '/protected':
            auth = request.getHeader('Authorization')
            if auth and auth.split(' ')[0] == 'Basic':
                decodeddata = base64.decodestring(auth.split(' ')[1])
                if decodeddata.split(':') == ['username', 'password']:
                    return "Authorized!"

            request.setResponseCode(401)
            request.setHeader('WWW-Authenticate', 'Basic realm="realmname"')
            return "Authorization required."
        else:
            url = bytes.decode(request.uri, 'utf-8')
            url_parts = url.split('?')
            function_to_run = mappings.get(url_parts[0])
            if function_to_run is None:
                return b''
            return function_to_run(request)


s = server.Site(DummyServer())
reactor.listenTCP(8080, s)
reactor.run()
