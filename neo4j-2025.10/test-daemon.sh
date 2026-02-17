#!/bin/bash

set -o errexit -o nounset -o errtrace -o pipefail -x

wait-for-it localhost:7474 --timeout=60

neo4j status | grep -i "Neo4j is running"
neo4j-admin server status | grep -i "Neo4j is running"

curl -fsSL localhost:7474/browser | grep "<title>Neo4j Browser</title>"

# Test database queries using cypher-shell
# Reference: https://neo4j.com/docs/getting-started/cypher/intro-tutorial/
query(){
    cypher-shell -u neo4j -p TestP@ss123 -a bolt://localhost:7687 "$@"
}

# Verify basic connectivity
query "RETURN 1 as result;" | grep "1"

# 1. Create data
# 1a. Create constraints
query << 'EOF'
    CREATE CONSTRAINT movie_title IF NOT EXISTS 
    FOR (m:Movie) REQUIRE m.title IS UNIQUE;

    CREATE CONSTRAINT person_name IF NOT EXISTS 
    FOR (p:Person) REQUIRE p.name IS UNIQUE;
EOF

# 1b. Insert The Matrix movie and actors
query << 'EOF'
    MERGE (TheMatrix:Movie {title:'The Matrix'}) 
    ON CREATE SET TheMatrix.released=1999, TheMatrix.tagline='Welcome to the Real World';

    MERGE (Keanu:Person {name:'Keanu Reeves'}) 
    ON CREATE SET Keanu.born=1964;

    MERGE (Carrie:Person {name:'Carrie-Anne Moss'});
    
    MATCH (Keanu:Person {name:'Keanu Reeves'}), (TheMatrix:Movie {title:'The Matrix'})
    MERGE (Keanu)-[:ACTED_IN {roles:['Neo']}]->(TheMatrix);
    
    MATCH (Carrie:Person {name:'Carrie-Anne Moss'}), (TheMatrix:Movie {title:'The Matrix'})
    MERGE (Carrie)-[:ACTED_IN {roles:['Trinity']}]->(TheMatrix);
EOF

query "MATCH (p:Person) RETURN COUNT(p) AS personCount;" | grep "2"

# 1c. Insert The Replacements movie and actors
query << 'EOF'
    MERGE (TheReplacements:Movie {title:'The Replacements'}) 
    ON CREATE SET TheReplacements.released=2000, TheReplacements.tagline='Glory lasts forever';

    MERGE (Keanu:Person {name:'Keanu Reeves'});
    
    MATCH (Keanu:Person {name:'Keanu Reeves'}), (TheReplacements:Movie {title:'The Replacements'})
    MERGE (Keanu)-[:ACTED_IN {roles:['Shane Falco']}]->(TheReplacements);
EOF

# Keanu was attempted to be created again in the second block
# but the constraint ensures no duplicates
query "MATCH (p:Person) RETURN COUNT(p) AS personCount;" | grep "2"

# 2. Read data
# 2a. Find movies released in the 1990s
query "MATCH (matrix:Movie {title:\"The Matrix\"}) RETURN matrix.released;" | grep "1999"
query "MATCH (replacement:Movie {title:\"The Replacements\"}) RETURN replacement.released;" | grep "2000"

nineties_movies=$(query << 'EOF'
    MATCH (nineties:Movie) 
    WHERE nineties.released > 1990 AND nineties.released < 2000 
    RETURN nineties.title
EOF
)
echo "$nineties_movies" | grep "The Matrix"
echo "$nineties_movies" | grep -v "The Replacements"

# 2b. Test actor-movie relationships
keanu_movies=$(query << 'EOF'
    MATCH (keanu:Person {name:"Keanu Reeves"})-[:ACTED_IN]->(movies:Movie) 
    RETURN COUNT(movies) AS keanu_movies;
EOF
)
echo "$keanu_movies" | grep "2"

carrie_movies=$(query << 'EOF'
    MATCH (carrie:Person {name:"Carrie-Anne Moss"})-[:ACTED_IN]->(movies:Movie) 
    RETURN COUNT(movies) AS carrie_movies;
EOF
)
echo "$carrie_movies" | grep "1"

matrix_actors=$(query << 'EOF'
    MATCH (matrix:Movie {title:"The Matrix"})<-[:ACTED_IN]-(actors:Person) 
    RETURN COUNT(actors) AS matrix_actors;
EOF
)
echo "$matrix_actors" | grep "2"

# 3. Update data
query "MATCH (carrie:Person {name:'Carrie-Anne Moss'}) RETURN carrie.born;" | grep "NULL"

query << 'EOF'
    MATCH (Carrie:Person {name:'Carrie-Anne Moss'}) 
    SET Carrie.born = 1967;
EOF

query "MATCH (carrie:Person {name:'Carrie-Anne Moss'}) RETURN carrie.born;" | grep "1967"

# 4. Delete data
query "MATCH (m:Movie) RETURN COUNT(m) AS movieCount;" | grep "2"

query << 'EOF'
    MATCH (TheReplacements:Movie {title:'The Replacements'}) 
    DETACH DELETE TheReplacements;
EOF

query "MATCH (m:Movie) RETURN COUNT(m) AS movieCount;" | grep "1"

keanu_movies=$(query << 'EOF'
    MATCH (keanu:Person {name:"Keanu Reeves"})-[:ACTED_IN]->(movies:Movie) 
    RETURN COUNT(movies) AS keanu_movies;
EOF
)
echo "$keanu_movies" | grep "1"
