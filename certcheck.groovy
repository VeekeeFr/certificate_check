def transformIntoStep(String workingDirectory, String[] chk_data) {
    return {
        node {
		stage(chk_data[0])
		{
			switch(chk_data[1])
			{
				case "https":
					sh "${workingDirectory}/certificate_check.sh -type https -url '${chk_data[2]}' -threshold ${threshold}"
					break
				case "static":
					sh "${workingDirectory}/certificate_check.sh -type static -data '${chk_data[2]}' -threshold ${threshold}"
					break
				case "jar":
					sh "${workingDirectory}/certificate_check.sh -type jar -url '${chk_data[2]}' -threshold ${threshold}"
				default:
					throw new Exception("Unknown command type '${chk_data[1]}'")
			}
		}
        }
    }
}

def processFile (String fileName, String threshold) {
	def HAS_FILE = sh (script: "ls ${fileName} ; exit 0", returnStdout: true).trim()
	if(! HAS_FILE.equals(""))
	{
		def FILE_PATH = sh (script: "dirname ${fileName}", returnStdout: true).trim()

		sh "chmod +x ${workspace}/*.sh"

		dir("${FILE_PATH}")
		{
			def stepsForParallel = [:]

			List<String> cmd_list = sh (script: "cat ${fileName}", returnStdout: true).trim().split("\n")
			for (String cmd : cmd_list) {
				if(cmd.startsWith('#') || cmd.length() < 2)
				{
					// Skip comments
					continue
				}
				chk_data = cmd.split(";")

				stepsForParallel["${chk_data[0]}"] = transformIntoStep("${workspace}", chk_data);
			}
			parallel stepsForParallel
		}
	} else {
		sh "echo 'File does not exist :('"
	}
}
return this