- OCSP
  NAC currently required to work with OCSP endpoint within internal subnet issued by internal CA and no requirement to send traffic over the internet, however, as a part of DEP(Digital Education Project) this service needed to onboard external CA which required NAC to send OCSP traffic over the internet.

- As a part of this we needed to provide a static set of IPS in order for the supplier to ALLOW-LIST NAC on their service.

Currently, NAC's cluster tasks are auto assigned with a public IP and these are subjected to change everytime service gets re-deployed.
In order to solve this problem a SOURCE-NAT was configured using AWS NAT Gateway for traffic bound to DEP OCSP IP range.

![High level solution outlining DEP OCSP traffic
](./documentation/azure-images/ocsp-nat.png)

- Limitation
  As per the best practice NAT should have been deployed in to multi-az, however, due to the limitation on the available subnet and CIDR limitation assigned to this VPC, it was not possible to deploy NAT across all availability zones without significant refactoring of the existing VPC.
- In the event of an availability zone failures NAC DEP service will be degraded until AWS brings back the service.This has been raised as risk.
