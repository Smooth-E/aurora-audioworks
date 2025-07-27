"""

"""
import logging

converter_logger = logging.getLogger("pydub.converter")

def log_conversion(conversion_command):
    converter_logger.debug("subprocess.call(%s)", repr(conversion_command))
    print("subprocess.call(%s)" + str(repr(conversion_command)))

def log_subprocess_output(output):
    if output:
        for line in output.rstrip().splitlines():
            converter_logger.debug('subprocess output: %s', line.rstrip())
            print('subprocess output: %s' + line.rstrip())
