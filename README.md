The primary objective was to collect, process, and analyze Azure Network Security Group (NSG) Flow Logs. Logs were stored in Azure Blob Storage and retrieved using AzCopy with Managed Identity authentication, eliminating the need to store credentials in scripts.

Automated log collection was implemented through scheduled Cron jobs. Logstash was used to ingest and parse JSON log records, extracting key network information such as source and destination IP addresses, ports, protocols, and traffic actions.

The processed data was forwarded to Elasticsearch for indexing and storage, while Kibana was used to create dashboards for visualization and analysis of network activity.

The environment also included Suricata, an IDS/IPS solution used for network traffic monitoring and threat detection, providing additional visibility into potentially suspicious or malicious connections.

This project provided hands-on experience with cloud network monitoring, log ingestion and processing, security analytics, automation, and the integration of open-source security tooling within an Azure environment.
