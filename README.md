# WS-Challenge-06   

1. Deploy the application
We generate the script [set_hostname.sh](./set_hostname.sh) that will set the environment variable `INGRESS_HOSTNAME` for the domain that will be used by the application. The script will also update the loca `/etc/hosts` file to resolve the domain name locally.
```sh
source set_hostname.sh
``` 

We also replace the host attribute in the `ingress.yaml`file with hostname defined in the prvious step.
After that we deploy the kubernetes resources

```sh
kubectl apply -f ./
``` 

Now we access the applciation through a browser and we see the following homepage:
![1-homepage](./assets/1-home.png)

2. Send traffic

As we already set the env variable on the previous step, here we'll need to run the python script

```sh
python3 test-challenge6.py --send_high_load
``` 

This shows the following output from the application pod:
![2-high-load](./assets/2-high_load.png)

From the Python script we also see that the response code is 200 until the request 200, then we start seeing an error 502 

After reviewed Python application, it is using a Limiter that will restricit the request to 200 for the root path `/`.

To fix this issue, we can use the Nginx controller Rate Limiting feature. This allow us to control the request frequency at the ingress layer, so that the traffic doesn't reach the service if we add a specific rule for that.

In this case, we used the k8s annotation: `nginx.ingress.kubernetes.io/limit-rpm`, with limit the number of request per minutes. To calculate the right value, we ned to consider that the value we set in the anotation will be multiplied by the burst multiplier (set to 5 by default) to set a burst limit. Ref: <https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#rate-limiting> 
Because the application is limited to 200 request, we will need to used a number that is less than that number, E.g 195, which requiers the `nginx.ingress.kubernetes.io/limit-rpm: 39`.
We are also considering that for this example there in only one user, with the same for all the request, and all request are sent as soon as possible. After adding the annotation mentioned before, we run the python script again:

```sh
python3 test-challenge6.py --send_high_load
``` 
Now the pod is not restarting nor showing the `ratelimit` error message. Also, from the Python outputs now we see the request 197 to be the latest one returning a 200 status code. Now from 198 and on, we see a status code 503, which differes from previous status code in the python execution witout the annotation. The reason is because the nginx controller returns and error 503 when ths rating limit is exceeded

Python output sample:
```log
...
Request 192: 200
Request 193: 200
Request 194: 200
Request 195: 200
Request 196: 200
Request 197: 200
Request 198: 503
Request 199: 503
Request 200: 503
Request 201: 503
Request 202: 503
...
```

3. Large headers requests
error from logs:
```log
upstream sent too big header while reading response header from upstream,
```

The application uses a token of 4000 characteres
```python
# Generate a random token with 4000 characters
token_length = 4000
random_token = secrets.token_hex(token_length // 2) 
```

Added the following annotations:
```yaml
nginx.ingress.kubernetes.io/proxy-buffering: "on"
nginx.ingress.kubernetes.io/proxy-buffer-size: "8k"
nginx.ingress.kubernetes.io/proxy-buffers: "4"
nginx.ingress.kubernetes.io/proxy-body-size: "8m"
```

4. Upload a file
Output:

```
File uploaded successfully: 200
```

