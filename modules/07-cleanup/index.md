---
layout: default
title: 7. Cleanup
nav_order: 8
---

# Cleanup
{: .no_toc }

---

## Delete All Resources

To remove all deployed resources:

```bash
cd deploy
bash teardown.sh
```

This deletes all 14 resource groups and their contents (VMs, storage, NSGs, IPs).

## Deallocate Only (Keep Resources)

To stop billing without destroying resources:

```bash
for region in australiacentral australiaeast australiasoutheast newzealandnorth eastasia southeastasia japaneast japanwest koreacentral koreasouth centralindia southindia indonesiacentral malaysiawest; do
  az vm deallocate --resource-group "rg-latency-$region" --name "vm-latency-$region" --no-wait
done
```

To restart later:

```bash
bash ensure-vms-ready.sh
```

## Cost Estimate

| Resource | Monthly Cost (14 regions) |
|----------|:-------------------------:|
| B2s VMs (running 24/7) | ~$420 |
| B2s VMs (deallocated) | $0 (disk only: ~$7) |
| Storage Accounts | ~$1.40 |
| Public IPs (allocated) | ~$42 |

> {: .tip }
> Deallocate VMs when not testing. Use `ensure-vms-ready.sh` to restart on demand.

---

[← Frontend Dashboard](../06-frontend/){: .btn .mr-2 }
[Back to Home →](../../){: .btn .btn-primary }
