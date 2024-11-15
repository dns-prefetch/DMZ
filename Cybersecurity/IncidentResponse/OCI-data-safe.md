---
<img src="https://dns-prefetch.github.io/assets/logos/dmz-header-2.svg" width="100%" height="10%">

##### Published 14/11/2024 17:18:06; Revised: None

# How Oracle Data Safe accesses the UNIFIED_AUDIT_TRAIL

<img src="../images/oracle-data-safe.svg">

Oracle **Data Safe** is a security and auditing service that helps organizations monitor, assess, and protect their Oracle Databases. It can read and analyze various database logs, including the **Unified Audit Trail** (`UNIFIED_AUDIT_TRAIL`), to enhance security monitoring, track user activity, and provide insights into potential risks or compliance issues.

## The Data Safe Architecture

The UNIFIED_AUDIT_TRAIL is a data dictionary view that captures audit policy events.  Some events are defined as part of the default configuration, but for protective monitoring perspective, your security team should be defining a fine grained event capture policy. The unified audit trail resides in a read-only table in the AUDSYS schema.

If we assume your security team have defined the Oracle database auditing policy for your organisation, the policy is deployed to existing databases and will be deployed to future databases, the next important consideration is how the audit events, currently locked inside the Oracle database UNIFIED_AUDIT_TRAIL table can be loaded into a data analytics solutions or a SIEM.

Another consideration, sometimes ignored, which can lead ultimately to an oversized AUDSYS schema tablespace, is the data retention cycle of the audit records.

The **Data Safe** service operates within a separate Oracle services tenancy, distinct from your own tenancy. To authenticate and authorize connections between the Data Safe service and your individual databases, a target database user account and password are required. Additionally, network routes and firewall rules must be configured to enable the necessary network traffic.

Data Safe connects to target databases using SQL\*Net. For enhanced security, Oracle recommends configuring Native Network Encryption (NNE) or Transport Layer Security (TLS), which Oracle refers to as **TCPS**. Implementing TCPS with mutual authentication (mTLS) involves installing X.509 certificates on both Data Safe and each target database. This process is complex within the Oracle ecosystem unless you're using Oracle Autonomous Database, which simplifies mTLS configuration and certificate management through the OCI dashboard. For non-Autonomous databases, managing certificates for each database typically requires significant effort, including either a dedicated Certificate Authority or a third-party vendor solution like **Venafi**.

Since Data Safe uses SQL\*Net to connect to target databases, it supports a wide range of distribution channels, including **Oracle FastConnect**, **Azure ExpressRoute**, **AWS Direct Connect**, and **Google Cloud Interconnect (GCS)**. While a Libreswan VPN tunnel across the internet may be an option for development or proof-of-concept environments, it is not recommended for production use. Configuring a VPN between Oracle Cloud and your customer premises equipment (CPE) introduces additional complexity and may introduce security risks, even with in-flight encryption. Furthermore, for SQL\*Net connections to a target database, the database must be accessible via a public endpoint on the internet, which is generally an impractical use case.

In practice, the optimal configuration for Data Safe involves using a direct **SQL\*Net** connection to the target database within Oracle Cloud, secured via an **mTLS/NNE** tunnel. This ensures that the connection never traverses the internet, providing a more secure and efficient setup. This should be the preferred approach for all direct SQL\*Net connections.

Oracle **Data Safe** assists in defining and enforcing audit policies for each target database, while also managing the data retention lifecycle for the **UNIFIED_AUDIT_TRAIL** table. Effective retention management is crucial, as high-traffic databases can generate a large volume of audit records that eventually need to be purged. A standard SQL DELETE statement may not be efficient enough to keep up with the removal of these records, so implementing a table partitioning strategy is recommended to improve performance and streamline the retention process.


### How Oracle Data Safe Connects to Oracle Database to Read the `UNIFIED_AUDIT_TRAIL`

Oracle Data Safe connects to an Oracle Database in the following way:

### 1. **Data Safe Configuration**

When setting up **Oracle Data Safe** for your Oracle Database, you need to configure it to connect to your database and collect audit data, including reading from the `UNIFIED_AUDIT_TRAIL`.

- **Prerequisites**: Before Data Safe can connect to an Oracle Database, certain conditions must be met:
  - **Unified Auditing** should be enabled in the Oracle Database, which is typically the case if you're using Oracle 12c or later.
  - **Data Safe User**: A specific user (usually `DSA_USER`) is created in the database, and this user must have the necessary privileges to read audit data and perform security assessments.
  - **Granting Privileges**: The user connecting Data Safe to the database must have appropriate privileges, typically the `AUDIT_VIEWER` role or direct `SELECT` access on the `UNIFIED_AUDIT_TRAIL`.

### 2. **Setting Up Oracle Data Safe**

To connect Oracle Data Safe to an Oracle Database, you typically follow these steps:

#### **Step 1: Enable Data Safe in Oracle Cloud**

1. **Log in to the Oracle Cloud Console**: Navigate to the **Oracle Data Safe** service from the main dashboard.
2. **Create a Data Safe Instance**: In Data Safe, create a new **Data Safe instance** if one does not already exist.

#### **Step 2: Register Your Oracle Database with Data Safe**

Once Data Safe is set up, you need to register the target Oracle Database (which you want to monitor) with Data Safe.

1. **Go to the Data Safe Instance** in the Oracle Cloud Console.
2. **Add Database**: Choose to register a new database, and enter details like the **Database Name**, **Service Name**, **Oracle SID**, **Hostname**, and **Connection Details** (including a user that has privileges to query the Unified Audit Trail).
3. **Configure Access Permissions**:
   - During the registration, you will specify a **Data Safe user** (usually `DSA_USER`), which must have the appropriate **SELECT** privileges on the `UNIFIED_AUDIT_TRAIL`.

#### **Step 3: Configure Required Privileges for Data Safe User**

You need to ensure that the `DSA_USER` (or equivalent user) has the following privileges:

1. **Querying Unified Audit Logs**: The user needs **`SELECT`** privileges on the `UNIFIED_AUDIT_TRAIL` in the target Oracle Database.

   Example of granting `SELECT` privilege:

   ```sql
   GRANT SELECT ON UNIFIED_AUDIT_TRAIL TO DSA_USER;
   ```

2. **`AUDIT_VIEWER` Role**: Alternatively, the user can be granted the `AUDIT_VIEWER` role, which includes the necessary permissions to access audit-related tables.

   Example:

   ```sql
   GRANT AUDIT_VIEWER TO DSA_USER;
   ```

#### **Step 4: Data Safe Retrieves Unified Audit Data**

Once the Oracle Database is registered with Oracle Data Safe, and the necessary privileges are granted to the Data Safe user, Data Safe can begin collecting audit data from the database, including reading records from the `UNIFIED_AUDIT_TRAIL`.

- **Audit Collection**: Oracle Data Safe periodically queries the `UNIFIED_AUDIT_TRAIL` to collect audit records, including login attempts, SQL execution, DDL operations, and other database activities. These logs are then used for security analysis and compliance reporting.

- **Data Safe Components**: The collected audit data is typically analyzed in the following components of Oracle Data Safe:
  - **Activity Monitoring**: You can monitor database activities, including user logins, DDL operations, and SQL execution, in real-time or through historical data.
  - **Audit Vault**: The unified audit trail can also be exported and integrated with **Audit Vault** for long-term storage and further analysis.
  - **Sensitive Data Discovery**: Data Safe can also discover sensitive data in your database and assess how it relates to the activity logs.

#### **Step 5: Review Audit Logs in Data Safe**

Once connected, Oracle Data Safe can help you review the unified audit logs. For example, you can:

- **View Audit Trails**: View detailed audit information, such as which users executed which SQL statements, when, and from where.
- **Correlate Events**: Correlate audit data with security events to detect unusual activity (e.g., privilege escalation, failed login attempts, changes to critical data).
- **Generate Reports**: Generate compliance and audit reports for internal audits or external regulatory needs (e.g., GDPR, SOX).

### 3. **Technical Workflow for Reading the Unified Audit Trail**

Here’s an overview of the technical flow:

1. **Database Setup**:
   - Ensure Unified Auditing is enabled in the Oracle Database.
   - Configure a user (such as `DSA_USER`) with sufficient privileges to query the `UNIFIED_AUDIT_TRAIL`.

2. **Data Safe Configuration**:
   - Register the Oracle Database with Oracle Data Safe.
   - Data Safe uses **Oracle Cloud Infrastructure (OCI)** APIs to connect to the target database.
   - Data Safe periodically queries the database to collect unified audit logs from the `UNIFIED_AUDIT_TRAIL`.

3. **Audit Log Access**:
   - Data Safe directly queries the `UNIFIED_AUDIT_TRAIL` using the credentials of the registered **Data Safe user**.
   - The logs are stored and analyzed for security risks, compliance, and audit purposes.

4. **Security and Privacy Considerations**:
   - Ensure that **network security** is in place, such as **Oracle Cloud Infrastructure (OCI) Vault** to store credentials securely.
   - Use **Oracle Data Safe**'s built-in encryption and access control features to protect the audit data.

### 4. **Benefits of Using Oracle Data Safe with Unified Audit Trail**

- **Centralized Audit Monitoring**: Oracle Data Safe allows you to centralize and monitor audit events from your Oracle Database, making it easier to detect and respond to suspicious activities.
- **Real-Time Security Insights**: By continuously collecting audit data, Data Safe provides real-time insights into database activities and potential security risks.
- **Compliance Support**: Data Safe assists with compliance audits by generating reports from the Unified Audit Trail, helping you meet regulatory requirements like GDPR, HIPAA, and SOC 2.
- **Enhanced Data Protection**: With Oracle Data Safe, you get additional capabilities such as sensitive data discovery, data masking, and user activity monitoring.

### Conclusion

Oracle **Data Safe** connects to your Oracle Database via the OCI platform and uses a **Data Safe user** (such as `DSA_USER`) to access and query the `UNIFIED_AUDIT_TRAIL`. It can then collect, analyze, and present audit data, helping you monitor database activity and meet security and compliance requirements.

By leveraging **Data Safe**, you gain enhanced visibility into both Oracle Database-level activities and potential security risks, which makes it a powerful tool for database administrators and security teams.

---
