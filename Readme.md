# about
packages [google/butteraugli](https://github.com/google/butteraugli) and [google/guetzli](https://github.com/google/guetzli) as docker container

# running

```bash
$ docker run -ti -v $(pwd):/data -w /data --read-only visualtools /butteraugli image.jpg image.jpg
0.000000
```

# building

```bash
docker build -t visualtools .
```