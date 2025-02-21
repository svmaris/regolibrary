package armo_builtins
# Deny mutating action unless user is in group owning the resource


#privileged pods
deny[msga] {

	pod := input[_]
	pod.kind == "Pod"
	container := pod.spec.containers[i]
	begginingOfPath := "spec."
	path := isPrivilegedContainer(container, i, begginingOfPath)

    msga := {
		"alertMessage": sprintf("the following pods are defined as privileged: %v", [pod.metadata.name]),
		"packagename": "armo_builtins",
		"alertScore": 3,
		"failedPaths": path,
         "alertObject": {
			"k8sApiObjects": [pod]
		}
     }
}


#handles majority of workload resources
deny[msga] {
	wl := input[_]
	spec_template_spec_patterns := {"Deployment","ReplicaSet","DaemonSet","StatefulSet","Job"}
	spec_template_spec_patterns[wl.kind]
	container := wl.spec.template.spec.containers[i]
	begginingOfPath := "spec.template.spec."
	path := isPrivilegedContainer(container, i, begginingOfPath)

    msga := {
		"alertMessage": sprintf("%v: %v is defined as privileged:", [wl.kind, wl.metadata.name]),
		"packagename": "armo_builtins",
		"alertScore": 3,
		"failedPaths": path,
         "alertObject": {
			"k8sApiObjects": [wl]
		}
     }
}

#handles cronjob
deny[msga] {
	wl := input[_]
	wl.kind == "CronJob"
	container := wl.spec.jobTemplate.spec.template.spec.containers[i]
	begginingOfPath := "spec.jobTemplate.spec.template.spec."
	path := isPrivilegedContainer(container, i, begginingOfPath)

    msga := {
		"alertMessage": sprintf("the following cronjobs are defined as privileged: %v", [wl.metadata.name]),
		"packagename": "armo_builtins",
		"alertScore": 3,
		"failedPaths": path,
         "alertObject": {
			"k8sApiObjects": [wl]
		}
     }
}


# Only SYS_ADMIN capabilite
isPrivilegedContainer(container, i, begginingOfPath) = path {
	not container.securityContext.privileged == true
	path = [sprintf("%vcontainers[%v].securityContext.capabilities.add[%v]", [begginingOfPath, format_int(i, 10), format_int(k, 10)]) | capabilite = container.securityContext.capabilities.add[k]; capabilite == "SYS_ADMIN"]
	count(path) > 0
}

# Only securityContext.privileged == true
isPrivilegedContainer(container, i, begginingOfPath) = path {
	container.securityContext.privileged == true
	path1 = [sprintf("%vcontainers[%v].securityContext.capabilities.add[%v]", [begginingOfPath, format_int(i, 10), format_int(k, 10)]) | capabilite = container.securityContext.capabilities.add[k]; capabilite == "SYS_ADMIN"]
	count(path1) < 1
	path = [sprintf("%vcontainers[%v].securityContext.privileged", [begginingOfPath, format_int(i, 10)])]
}

# SYS_ADMIN capabilite && securityContext.privileged == true
isPrivilegedContainer(container, i, begginingOfPath) = path {
	path1 = [sprintf("%vcontainers[%v].securityContext.capabilities.add[%v]", [begginingOfPath, format_int(i, 10), format_int(k, 10)]) | capabilite = container.securityContext.capabilities.add[k]; capabilite == "SYS_ADMIN"]
	count(path1) > 0
	container.securityContext.privileged == true
	path = array.concat(path1, [sprintf("%vcontainers[%v].securityContext.privileged", [begginingOfPath, format_int(i, 10)])])
}