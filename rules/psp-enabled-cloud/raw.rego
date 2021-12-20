package armo_builtins


# Check if PSP is enabled for GKE
deny[msga] {
	clusterConfig := input[_]
	clusterConfig.apiVersion == "container.googleapis.com/v1"
	clusterConfig.kind == "Describe"
    clusterConfig.metadata.provider == "gke"	
	config := clusterConfig.data
    not config.podSecurityPolicyConfig.enabled == true


	
	
	msga := {
		"alertMessage": "pod security policy configuration is not enabled",
		"alertScore": 9,
		"packagename": "armo_builtins",
		"failedPaths": [],
		"alertObject": {
			"k8sApiObjects": [],
            "externalObjects": clusterConfig
		}
	}
}

# TODO - EKS. By default has a policy which allows everything