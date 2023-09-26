from twisted.internet import reactor
from twisted.web import server, resource

from spatialserverfunctions import *

GET_mappings = {
    '/': return_home_page,
    '/index': return_home_page,
    '/install_server': install_server
}

POST_mappings = {
    '/geometry_intersection': geometry_intersection
}


class DummyServer(resource.Resource):
    isLeaf = True

    def render_GET(self, request):
        url = bytes.decode(request.uri, 'utf-8')
        url_parts = url.split('?')
        function_to_run = GET_mappings.get(url_parts[0])
        if function_to_run is None:
            request.setResponseCode(400)
            return b'No such page'
        return function_to_run(request)

    def render_POST(self, request):
        url = bytes.decode(request.uri, 'utf-8')
        url_parts = url.split('?')
        function_to_run = POST_mappings.get(url_parts[0])
        if function_to_run is None:
            request.setResponseCode(400)
            return b'No such page'
        return function_to_run(request)


s = server.Site(DummyServer())
reactor.listenTCP(8090, s)
reactor.run()
