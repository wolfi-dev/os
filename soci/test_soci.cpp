#include <soci/soci.h>
#include <soci/postgresql/soci-postgresql.h> // This is crucial
#include <iostream>
#include <string>
#include <cassert>

using namespace std;
using namespace soci;

int main() {
    try {
        soci::session sql("postgresql://dbname=testdb user=wolfi");
        int id = 1; // Assuming this is the ID of the inserted record
        string name;
        int salary;

        sql << "select name, salary from persons where id = :id", use(id), into(name), into(salary);

        // Check if the returned values match the expected "Wolfi Rocks" and 50000
        assert(name == "Wolfi Rocks" && salary == 50000);

        cout << "Test Passed: Name: " << name << ", Salary: " << salary << endl;
    } catch (const soci::soci_error& e) {
        cerr << "Database error: " << e.what() << endl;
        return 1;
    } catch (const exception& e) {
        cerr << "Error: " << e.what() << endl;
        return 1;
    }

    return 0;
}
