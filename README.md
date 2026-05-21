 GROUP MEMBER NAME             ID
AMOTS ASRAT                 8371/17
EZEDIN KEDIR                8110/17
SILESHI WERETAW             8309/17
SINIMONA TOLOSA             8176/17
BABEY SISAY                 8099/17
CHERNET ABRHAM              7826/17
AYANTU ABERA                7731/17
MESAY MESFIN                8164/17
NEGALIGN TESHALA            7986/17
SAMUEL ABIRHAM              7849/17
SOLOMON BIRHANU             4592/16

Distributed Database Design Report for Ethiopian Ride-Hailing Platform 

The distributed database design for the Ethiopian ride-hailing platform is developed to support large-scale operations across multiple cities, including Addis Ababa, Adama, and Hawassa. The system must handle thousands of concurrent ride requests, real-time driver location updates, and secure payment transactions while maintaining data consistency, reliability, and low latency. The design emphasizes scalability, fault tolerance, and efficient data access for both drivers and riders in geographically distributed environments.


The platform connects riders and drivers through a mobile application that manages user registration, authentication, real-time driver tracking, ride requests, payments, and fraud detection. Because of Ethiopia’s diverse network conditions and geographic spread, the database must be distributed to minimize latency and ensure local availability even during network interruptions. Each city node operates semi-independently but remains synchronized with other nodes through replication and coordination services.


The main objectives of the distributed design are scalability, low latency, consistency, fault tolerance, security, and geographic distribution. Scalability ensures that the system can handle thousands of concurrent ride requests during peak hours. Low latency minimizes response time for ride matching and driver updates. Consistency maintains ACID properties for critical transactions such as ride booking and payments. Fault tolerance ensures data durability and recovery in case of node or network failures. Security protects sensitive user and payment data through encryption and access control, while geographic distribution optimizes data placement across cities to reduce cross-region traffic and improve performance.







The system architecture follows a hybrid distributed model that combines horizontal fragmentation and replication. Each city operates as a semi-autonomous data node, while a central coordination service manages global consistency and metadata. The architecture includes city nodes that store local data, a global coordinator that manages metadata and inter-city requests, a replication service for synchronization, a load balancer for routing requests, and a message queue for asynchronous updates such as driver location streaming and audit logs. This design ensures that even if one city node fails, other nodes can continue operating independently.
The technology stack includes PostgreSQL with the PostGIS extension for geospatial queries, logical replication for selective data sharing, Apache Kafka for event streaming, Redis for caching frequently accessed data, and cloud or local storage for backups. PostgreSQL provides strong ACID compliance and supports spatial indexing for efficient location-based queries. Kafka enables real-time communication between services, while Redis improves performance by caching active driver data and recent ride requests.
 

Replication is implemented using both synchronous and asynchronous methods. Synchronous replication is used for critical data such as ride bookings and payments to ensure strong consistency, while asynchronous replication is used for non-critical data such as driver locations and logs to improve performance. The replication topology follows a multi-master model, allowing each city node to handle local writes while synchronizing with others through conflict resolution policies. Conflicts are resolved using timestamp-based last-write-wins for location updates and transactional locks for ride bookings. This ensures that no driver is double-booked and that all ride transactions remain consistent across nodes.










Data consistency and concurrency control are maintained through appropriate isolation levels and distributed transactions. Serializable isolation is used for ride booking and payment transactions to prevent anomalies. Read committed isolation is used for analytics and reporting queries, while snapshot isolation is used for concurrent reads of driver availability. Distributed transactions are managed using the two-phase commit protocol, ensuring atomicity across nodes. Pessimistic locking prevents double-booking of drivers, while optimistic locking is used for driver location updates to reduce contention and improve throughput.
 
Network and latency optimization techniques include edge caching of frequently accessed data, GeoDNS routing to direct users to the nearest node, compression to reduce bandwidth usage, and batch updates to minimize network overhead. These optimizations are crucial in Ethiopia, where network reliability and bandwidth can vary significantly between regions. By processing most requests locally and replicating asynchronously, the system achieves both speed and resilience.


Security and compliance are ensured through AES-256 encryption for data at rest, TLS for data in transit, role-based access control, immutable audit logs for fraud detection, and data masking for sensitive fields in analytics queries. Role-based access ensures that only authorized personnel can access sensitive data such as payment information. Audit logs are replicated across nodes to prevent tampering and support fraud investigations. Data masking ensures that analysts can work with anonymized data without compromising privacy.



Monitoring and performance metrics are collected using Prometheus and visualized through Grafana. Metrics include query latency, replication lag, transaction throughput, and node uptime. Alerts are triggered for replication delays, node failures, or abnormal transaction rates. Continuous monitoring allows proactive maintenance and quick response to performance issues. The system can automatically scale resources during peak hours to maintain consistent performance.





Scalability and future enhancements include dynamic sharding for new city nodes, microservices integration for independent service evolution, machine learning for predictive surge pricing and fraud detection, and edge analytics for city-level performance insights. As the platform expands to more Ethiopian cities, new nodes can be added seamlessly without disrupting existing operations. Machine learning models can analyze historical data to predict demand surges and detect fraudulent behavior in real time.










In conclusion, the distributed database design ensures scalability, reliability, and security for the Ethiopian ride-hailing platform. By combining horizontal fragmentation, selective replication, and robust fault-tolerance mechanisms, the system can handle high concurrency, maintain ACID compliance, and recover gracefully from failures. The architecture provides a strong foundation for future expansion into additional cities and supports advanced analytics capabilities for operational optimization. This design not only meets current operational needs but also positions the platform for long-term growth, innovation, and resilience in Ethiopia’s evolving digital transportation ecosystem.

