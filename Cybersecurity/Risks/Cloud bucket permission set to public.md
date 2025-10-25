---
<img src="https://raw.githubusercontent.com/dns-prefetch/DMZ/refs/heads/main/Assets/images/global/dmz-header.svg" width="100%" height="10%">

##### Published 06/11/2024 10:40:04; Revised: Never

# Cloud buckets open to the public

OWASP Cloud-Native Application Security Top 10 document [CNAS-1: Insecure cloud, container or orchestration configuration](https://owasp.org/www-project-cloud-native-application-security-top-10/).

There have been several high-profile cases of cloud storage buckets being left publicly accessible, exposing sensitive data. These incidents typically involve misconfigurations of cloud storage permissions, such as Amazon S3 buckets or Google Cloud Storage, where the bucket is set to "public" or "open to the internet," making data accessible to anyone.

The author has personally worked with data migration teams that incompetently struggled to create time limited pre-authorized keys for read/write access to cloud buckets over the internet, so defaulted to creating a publically wide open bucket, then after the migration, walked away from the project leaving the customers data exposed for weeks.

### 1. **Amazon S3 Bucket Leaks (2017–2020)**
   **Amazon Web Services (AWS)** S3 buckets are commonly used to store data, and several breaches occurred due to misconfigurations of these buckets being set to public or with overly permissive access policies. Notable incidents include:

   - **Verizon (2017)**: A publicly accessible AWS S3 bucket exposed 14 million customer records, including names, addresses, and account details. The bucket was left unprotected with no password or encryption.
   - **Accenture (2017)**: Over 140 GB of data, including proprietary data and user credentials, were left exposed on an S3 bucket.
   - **FedEx (2018)**: FedEx’s subsidiary, TNT Express, left an S3 bucket containing sensitive data exposed, including shipping details, customer data, and financial records.
   - **Unison (2019)**: An exposed S3 bucket containing the personal data of over 100 million users was found. The bucket included details like names, social security numbers, and driver’s license information.

### 2. **Google Cloud Storage Leaks (2019–2020)**
   A significant number of breaches also occurred on **Google Cloud Storage** platforms, especially where public read/write permissions were mistakenly enabled.

   - **Collection #1 (2019)**: A massive data breach revealed over 2.7 billion records of usernames, email addresses, and passwords. Although the breach was attributed to compromised credentials from other platforms, the data was stored in publicly accessible cloud storage, which made it easier for malicious actors to obtain.
   - **Amazon Web Services & Google Cloud Exposure (2020)**: Researchers discovered thousands of exposed Google Cloud Storage and AWS S3 buckets holding sensitive data, including logs, application source code, and data backups. Many were improperly configured to be publicly accessible, often without encryption.

### 3. **MongoDB and Elasticsearch Data Exposed in Cloud Buckets (2018–2020)**
   Various **Elasticsearch** and **MongoDB** servers have been found exposed on cloud platforms like AWS, Google Cloud, and Microsoft Azure. These instances often include publicly accessible storage of sensitive data, such as customer details, credit card information, and private databases, due to misconfigurations in cloud environments.

   - **Elasticsearch Exposures (2018)**: Many Elasticsearch databases stored on cloud services were discovered publicly accessible with minimal or no authentication. These databases often included sensitive personal and financial information.
   - **MongoDB Ransomware Incidents (2020)**: Cybercriminals accessed unprotected MongoDB instances on cloud servers, often hosted on AWS or Google Cloud, and demanded ransom payments from organizations to restore access to their data.

### 4. **U.S. Army Intelligence (2017)**
   A major data exposure occurred when an **AWS S3 bucket**, containing sensitive files related to military intelligence, was left publicly accessible. The exposed data included sensitive files related to the **U.S. Army Intelligence and Security Command** (INSCOM), including internal documents, passwords, and encryption keys.

### 5. **Facebook (2019)**
   Facebook suffered a significant data breach when **Amazon S3 buckets** used by third-party apps were left publicly accessible. These third-party apps had improperly configured settings that exposed over 540 million Facebook records, including user IDs, phone numbers, and comments.

### Key Reasons for Cloud Bucket Data Breaches:
1. **Misconfigured Permissions**: The most common reason is leaving the bucket permission set to "public" (i.e., read access granted to everyone), or giving too much write access to unauthorized parties.
2. **Lack of Encryption**: Storing sensitive data without encryption, especially on a publicly accessible bucket, increases the likelihood of a breach.
3. **Unsecured Backup Data**: In some cases, organizations mistakenly upload backup data to cloud storage and leave it unprotected.
4. **Not Monitoring Access Logs**: Without monitoring tools in place, it's difficult to detect and respond to unauthorized access to cloud buckets.

### How to Prevent Cloud Bucket Data Breaches:
- **Restrict Bucket Access**: Ensure only authorized users can access the bucket by setting the correct permissions and using IAM (Identity and Access Management) roles.
- **Enable Encryption**: Always encrypt data in transit and at rest, even when storing it in cloud storage.
- **Monitor & Audit Logs**: Regularly audit and monitor access logs to detect potential unauthorized access or anomalies.
- **Set Up Alerts**: Configure automated alerts to notify administrators when there is an attempt to access the bucket or if permissions change unexpectedly.
- **Use "Private by Default" Settings**: Many cloud providers default to private access for newly created buckets, but some configurations might require explicitly setting the default to private.

These incidents highlight the importance of proper cloud storage configuration and vigilance in securing sensitive data to prevent public exposure.

---