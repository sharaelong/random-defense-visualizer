from http.server import BaseHTTPRequestHandler, HTTPServer
import subprocess
import os

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/drawfig'):
            # Extract range parameters from the URL
            _, _, range_from, range_to = self.path.split('/')

            # Run the shell script
            subprocess.run(['./run.sh', 'drawfig', range_from, range_to])

            # Serve the generated image
            self.send_response(200)
            self.send_header('Content-type', 'image/png')
            self.end_headers()
            with open('fig.png', 'rb') as file:
                self.wfile.write(file.read())
        else:
            self.send_response(404)
            self.end_headers()

def run(server_class=HTTPServer, handler_class=RequestHandler):
    server_address = ('', 8000)
    httpd = server_class(server_address, handler_class)
    print('Starting httpd...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
