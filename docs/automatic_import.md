# Protected Planet Monthly WDPA Release Import

The new Protected Planet website is designed to make importing and displaying
the WDPA monthly releases as easy and fast as possible.

## What you have to do

The process is simple, and almost identical to the current procedure for
sharing the WDPA releases with other partners.

Currently, the WDPA is released each month by uploading them to [Amazon Web
Services S3](http://aws.amazon.com/s3/), and sharing the link externally.
Similarly, the new Protected Planet import works by uploading the **same** WDPA
`.zip` file to a different folder on S3. Protected Planet watches this folder
for new files, and attempts to import any new WDPA releases it sees.

### Process

1. Create a WDPA Release `.zip` as normal.
2. Using Cloudberry (or any other S3 software), upload the `.zip` file (and
only that file) to the `pp-import-production` folder.

That's it! Protected Planet will start importing the release straight away and
requires no further input from you.

## How long does it take?

The import itself takes approximately **10 hours**. However it is designed to
minimise website downtime, only taking protectedplanet.net offline for up to 10
minutes.

## Troubleshooting

Currently there is no status reporting for the import process. As such, please
wait 24 hours after starting an import to ensure that it is completed.

If, after 24 hours, the import still does not appear to have worked, contact an
Informatics team member who will be able to help.
