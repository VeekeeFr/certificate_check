#!/usr/bin/env bash

export SCRIPT=$(readlink -f $0)
export SCRIPTPATH=`dirname $SCRIPT`

export CERT_TYPE=""
export CERT_URL=""
export CERT_DATA=""
export CHECK_THRESHOLD="81"

function usage
{
	echo "Usage:"
	echo "       $0 -type https -url <domaine:port> [-threshold <days number>]"
	echo "       $0 -type static -data <fixed date (yyyy-mm-dd)> [-threshold <days number>]"
	echo "       $0 -type jar -url <jar URL> [-threshold <days number>]"
	echo "       $0 -type jar -data <jar file location> [-threshold <days number>]"
	echo "Default threshold: ${CHECK_THRESHOLD} days"
}

while [ "$1" != "" ]; do
    case $1 in
	-h | --h | -help | --help)
		usage
		exit 98
		;;
	-type)
		shift
		case $1 in
			https|static|jar)
			;;
			*)
		   		echo "ERROR: Type '$1' is not supported"
				usage
		                exit 99
		esac
		CERT_TYPE="${1}"
		;;
	-url|--url)
		shift
		CERT_URL="${1}"
		;;
	-data|--data)
		shift
		CERT_DATA="${1}"
		;;
	-threshold|--threshold)
		shift
		CHECK_THRESHOLD="${1}"
		;;
	* )
   		echo "ERROR: Argument '$1' is not supported"
		usage
                exit 99
    esac
    shift
done

function check_argument
	{
		if [ "x${2}" == "x" ]
		then
			echo "ERROR: Argument ${1} has not been set!"
			exit 99
		fi
	}

function check_date
	{
		echo "Checking date '${1}'"
		epoch_now=$(date +%s)
		epoch_end=$(date +%s -d "${1}")

		if [ ${epoch_now} -lt ${epoch_end} ]
		then
			seconds_to_expire=$(($epoch_end - $epoch_now))

			warning_seconds=$((86400 * ${CHECK_THRESHOLD}))

			if [ "${seconds_to_expire}" -lt "${warning_seconds}" ]; then
				echo "WARNING: Certificate is about to expire!"
				exit 2
			fi
		else
			echo "ERROR: Certificate has expired!"
			exit 1
		fi
		echo "Date is valid!"
	}

# Inspired by https://superuser.com/questions/618370/check-expiry-date-of-ssl-certificate-for-multiple-remote-servers
function check_https
	{
		echo "Checking certificate from domain ${1}"
		SERVERNAME=`echo ${1} | awk -F':' '{ print $1 }'`
		output=$(echo | openssl s_client -servername ${SERVERNAME} -connect ${1} 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -subject -dates 2>/dev/null)

		if [ "$?" -ne 0 ]; then
			echo "ERROR: Connection failed!"
			exit 10
		fi

		end_date=$(echo $output | sed 's/.*notAfter=\(.*\)$/\1/g')

		echo "Date found: ${end_date}"

		check_date "${end_date}"
	}

function check_jar
	{
		if [ ! -f "${JAVA_HOME}/bin/jarsigner" ]; then
			echo "ERROR: JDK couldn't be found (${JAVA_HOME}/bin)!"
			exit 10
		fi

		TMP_FILE="${SCRIPTPATH}/tmp.jar"

		if [ "${1}" != "" ]
		then
			echo "Checking certificate from jar resource (${1})"

			wget --quiet -O ${TMP_FILE} ${1}

			if [ "$?" -ne 0 ]; then
				echo "ERROR: Resource retrieval failed!"
				exit 10
			fi
		else
			echo "Checking certificate from jar file (${2})"
			TMP_FILE="${2}"
		fi

		if [ ! -f ${TMP_FILE} ]; then
			echo "ERROR: Resource retrieval failed (empty file)!"
			exit 10
		fi

		end_date=$(${JAVA_HOME}/bin/jarsigner -verify -verbose -certs ${TMP_FILE} | grep "certificate is valid from " | head -1 | awk -F' to ' '{ print $2 }' | awk -F' ' '{ print $1 }')

		if [ "${1}" != "" ]
		then
			rm -f ${TMP_FILE}
		fi
		echo "Date found: ${end_date}"

		if [ "x${end_date}" == "x" ]; then
			echo "ERROR: couldn't retreive date from jar file!"
			exit 10
		fi

		check_date "20${end_date:6:2}-${end_date:3:2}-${end_date:0:2}"
	}

case ${CERT_TYPE} in
	https)
		check_argument "-url" "${CERT_URL}"
		check_https "${CERT_URL}"
		;;
	static)
		check_argument "-data" "${CERT_DATA}"
		check_date "${CERT_DATA}"
		;;
	jar)
		check_argument "-url/-data" "${CERT_URL}${CERT_DATA}"
		check_jar "${CERT_URL}" "${CERT_DATA}"
		;;
	*)
		echo "ERROR: Type should be set!"
		exit 99
esac
