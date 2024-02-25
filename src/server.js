import http from 'http';

const server = http.createServer((req, res) => {
    if (req.url.startsWith('')) {
        const urlParams = new URLSearchParams(req.url.split('?')[1]);
        const code = urlParams.get('code');
        
        res.statusCode = 200;
        res.setHeader('Content-Type', 'text/plain');
        res.end(`Authorization Code Capturado!\n code: ${code} \n`);    
    }
});

server.listen(3000, () => {
    console.log('Servidor em execução na porta 3000');
});
