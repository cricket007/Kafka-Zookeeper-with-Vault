lines = open('/etc/hosts').readlines()
open('/etc/hosts', 'w').writelines(lines[0:3])