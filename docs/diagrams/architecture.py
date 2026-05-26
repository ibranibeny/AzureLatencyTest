"""
Generate architecture diagrams for Azure APAC Latency Test workshop.
Uses https://github.com/mingrammer/diagrams
Run: python3 architecture.py
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.azure.compute import VM
from diagrams.azure.storage import BlobStorage
from diagrams.azure.network import PublicIpAddresses, NetworkSecurityGroupsClassic
from diagrams.onprem.client import Users
from diagrams.programming.framework import Angular

# --- Diagram 1: High-Level Architecture ---
with Diagram(
    "Azure APAC Latency Test",
    filename="azure_latency_architecture",
    show=False,
    direction="LR",
    graph_attr={"fontsize": "28", "bgcolor": "white"},
):
    client = Users("Browser / CLI")

    with Cluster("× 14 APAC Regions"):
        with Cluster("Per-Region Resources"):
            vm = VM("B2s VM\nws-echo + nginx")
            nsg = NetworkSecurityGroupsClassic("NSG\n80, 8080")
            pip = PublicIpAddresses("Public IP")
            blob = BlobStorage("Storage Account\nStatic Website")

    client >> Edge(label="WebSocket :8080", color="darkgreen", style="bold") >> pip
    client >> Edge(label="HTTP HEAD :80", color="blue") >> pip
    client >> Edge(label="HTTPS GET", color="orange", style="dashed") >> blob
    pip >> nsg >> vm


# --- Diagram 2: Detailed Per-Region Stack ---
with Diagram(
    "Per-Region Resource Stack",
    filename="azure_latency_per_region",
    show=False,
    direction="TB",
    graph_attr={"fontsize": "24", "bgcolor": "white"},
):
    client = Users("Client")

    regions = [
        "Australia East", "Australia Central", "Australia Southeast",
        "New Zealand North", "East Asia", "Southeast Asia",
        "Japan East", "Japan West", "Korea Central", "Korea South",
        "Central India", "South India", "Indonesia Central", "Malaysia West",
    ]

    with Cluster("Azure APAC (14 Regions)"):
        # Show 3 representative regions
        for region_name in ["Southeast Asia", "Japan East", "Australia East"]:
            with Cluster(region_name):
                vm = VM("vm-latency")
                pip = PublicIpAddresses("pip-latency")
                nsg = NetworkSecurityGroupsClassic("nsg-latency")
                blob = BlobStorage("latency-blob")
                pip >> nsg >> vm
                client >> Edge(color="darkgreen") >> pip
                client >> Edge(color="orange", style="dashed") >> blob

        with Cluster("... + 11 more regions"):
            VM("vm-latency-*")


# --- Diagram 3: Data Flow ---
with Diagram(
    "Latency Measurement Flow",
    filename="azure_latency_dataflow",
    show=False,
    direction="LR",
    graph_attr={"fontsize": "24", "bgcolor": "white"},
):
    browser = Angular("Angular\nDashboard")

    with Cluster("Measurement Types"):
        with Cluster("WebSocket RTT"):
            ws_vm = VM("ws-echo\nPort 8080")

        with Cluster("HTTP Ping"):
            http_vm = VM("nginx\nPort 80")

        with Cluster("Blob Latency"):
            storage = BlobStorage("Static Website\nHEAD request")

    browser >> Edge(label="WS connect + echo", color="darkgreen", style="bold") >> ws_vm
    browser >> Edge(label="HEAD /ping", color="blue") >> http_vm
    browser >> Edge(label="HEAD blob", color="orange", style="dashed") >> storage
