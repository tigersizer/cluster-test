from cassandra.cluster import Cluster
if __name__ == "__main__":
    cluster = Cluster(['cass3.cluster.test'],port=9042)
    session = cluster.connect('cluster',wait_for_all_pools=True)
    session.execute('USE cluster')
    rows = session.execute('SELECT * FROM named_zone')
    for row in rows:
        print(row.zone,row.name,row.ipv4)
