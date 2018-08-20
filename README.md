qamd-web is a front end, based on the [Yii 2](http://www.yiiframework.com/) framework, for the [QAMyData](https://github.com/Raymanns/qamd) tool.

It includes a Dockerfile for building the required packages and running the system, so all you need to do is check out this repository then:

	docker build -t acspri/qamd-web .
    docker-compose up -d
    
You can then access the application through the following URL:

    http://127.0.0.1:8000

**NOTES:** 
- Minimum required Docker engine version `17.04` for development (see [Performance tuning for volume mounts](https://docs.docker.com/docker-for-mac/osxfs-caching/))

