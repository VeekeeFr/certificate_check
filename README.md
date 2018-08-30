# certificate_check
Checks certificate validity (from HTTPS, jar or fixed date) and returns 0/1 depending of the options

# Usage
./certificate_check.sh -type https -url <domaine:port> [-threshold <days number>]

./certificate_check.sh -type static -data <fixed date (yyyy-mm-dd)> [-threshold <days number>]

./certificate_check.sh -type jar -url <jar URL> [-threshold <days number>]

./certificate_check.sh -type jar -data <jar file location> [-threshold <days number>]

Default threshold: 81

# Return values
0: Certificate is valid

1: Certificate has expired

2: Certificate is about to expire

10: Resource retreival failed

9X: invalid argument

# Jenkins integration
This script as been build for a Jenkins integration, though it can easily be adapted for any ecosystem. A sample Jenkinsfile (and its groovy script) is provided as-is.