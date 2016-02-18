# ci-server
A simple CI server that runs tests on your repo. Aims to be very extendable and
configurable.

Currently a very early project but the goal is to have:

* **Webhook** for CI builds from e.g. Github or Bitbucket
* **Docker containers** that the tests run in. Instead of checking out into a subdir a docker container will be started
that runs all tests. This will keep the code *isolated and sandboxed*. (*opt in*, checkin to subdir should still be possible)
* Fetch script that fetches repo and checks for any updates. Runs a new build for each new commit (*opt in*)
* Work with **Github Pull** requests (*opt in*)
* Push status of builds to **Slack** (*opt in*)
* Simple web frontend with Node where it is possible to see output from `user-script.sh` (*opt in*, run server and provide
domain name, open ports etc to make it public)

## Usage
### 1. Add config
Rename `default-config.cfg` to `config.cfg` and add your repo url. 

```bash
// config.cfg
repo_url="https://github.com/halmhatt/ci-server.git"
// followed by defaults...
```

If the server that you run this on is able to checkout with ssh then you could also use a ssh url.

### 2. Test script
There is a file called `user-script.sh`. This will be run **in the repo after checkout**. 
Add anything you want into this file and make it return a **none zero** exit code if tests fail. 

This file looks something like this as default

```bash
npm install
npm test
```

This will install all npm dependencies and then run the tests. But you could do anything, `bower install`, `make test`, `pip install`...

### 3. Run
Execute the file `runner.sh`

```bash
$ ./runner.sh
```

This should create a build directory `build/0001` and checkout your code to `build/0001/repo`.
