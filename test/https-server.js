if (process.argv.length <= 2) {
    throw 'Missing port number.';
}
var port = parseInt(process.argv[2], 10);
if (!port || port < 1 || port > 65535) {
    throw 'Invalid port number.';
}

var path = require('path'),
    fs = require('fs');

require('https').createServer(
    {
        key: fs.readFileSync(path.join(__dirname, 'certs', 'certificate.key')),
        cert: fs.readFileSync(path.join(__dirname, 'certs', 'certificate.crt')),
    },
    function (request, response) {
        response.writeHead(200);
        response.end("It works!\n");
    }
).listen(port);

console.log('ready');