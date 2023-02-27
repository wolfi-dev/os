package main

import (
	"bufio"
	apkotypes "chainguard.dev/apko/pkg/build/types"
	"chainguard.dev/melange/pkg/build"
	"fmt"
	"gopkg.in/yaml.v3"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

type GeneratedMelangeConfig struct {
	Package              build.Package                `yaml:"package"`
	Environment          apkotypes.ImageConfiguration `yaml:"environment,omitempty"`
	Pipeline             []build.Pipeline             `yaml:"pipeline,omitempty"`
	Subpackages          []build.Subpackage           `yaml:"subpackages,omitempty"`
	GeneratedFromComment string                       `yaml:"-"`
}

var pythonVersions = [2]string{"3.11", "3.10"}

var mconvert = "/home/strongjz/Documents/code/go/bin/mconvert"

func main() {
	cwd, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	dir, err := filepath.Abs("../..")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	pyMatch, err := regexp.Compile("py3-[a-z]+.yaml")
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	yamlFiles, err := os.ReadDir(dir)
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	// files that could not be generated manually
	var manualEdits []string
	var updates []GeneratedMelangeConfig

	for i := range yamlFiles {
		if pyMatch.MatchString(yamlFiles[i].Name()) && !yamlFiles[i].IsDir() {

			fmt.Printf("Reading File: %s\n", yamlFiles[i].Name())
			data, err := os.ReadFile(dir + "/" + yamlFiles[i].Name())
			if err != nil {
				fmt.Printf("Error Opening file %s %s \n", yamlFiles[i].Name(), err)
				os.Exit(1)
			}

			var dataYaml GeneratedMelangeConfig
			err = yaml.Unmarshal(data, &dataYaml)
			if err != nil {
				fmt.Printf("Error unmarshalling %s\n", err)
				os.Exit(1)
			}

			name := dataYaml.Package.Name
			version := dataYaml.Package.Version
			/*
				epoch := dataYaml.Package.Epoch
				want := fmt.Sprintf("build-package,${%s},${%s}-r${%v}", name, version, epoch)
			*/

			updates = append(updates, dataYaml)

			newName := strings.Split(name, "-")
			for p := range pythonVersions {
				fmt.Printf("Converting file %s version %s python %s\n", newName[1], version, pythonVersions[p])
				cmd := exec.Command(mconvert, "python", newName[1], "--package-version", version, "--python-version", pythonVersions[p])
				err := cmd.Run()
				if err != nil {
					fmt.Printf("Error running mconvert for %s %s\n", newName[1], err)
					// issue with a version will lead to others so stop and record it
					manualEdits = append(manualEdits, newName[1])
					break
				}
			} //end python version conversions
		} //match on python files
	} //end search of yaml files

	//read in all the new python files
	/*	cwd, err := os.Getwd()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}*/

	//Now update the makefile with the version
	makefile, err := os.Open(dir + "/Makefile")
	if err != nil {
		fmt.Printf("Could not find Makefile: %s", err)
		os.Exit(1)
	}
	defer makefile.Close()

	var lines []string
	scanner := bufio.NewScanner(makefile)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		fmt.Printf("Could not scan Makefile: %s", err)
		os.Exit(1)
	}

	var makefileManualUpdates []string
	for i := range updates {
		// index of old makefile entry
		index := Find(lines, fmt.Sprintf("$(eval $(call build-package,%v,%v-r%v))", updates[i].Package.Name, updates[i].Package.Version, updates[i].Package.Epoch))
		if index == len(lines) {
			break
		}

		for p := range pythonVersions {
			updatePackage := strings.Split(updates[i].Package.Name, "-")
			updateName := fmt.Sprintf("py%v-%v", pythonVersions[p], updatePackage[1])
			//$(eval $(call build-package,py3-botocore,1.21.49-r0))
			update := fmt.Sprintf("$(eval $(call build-package,%v,%v-r0))", updateName, updates[i].Package.Version)
			//replace old with new

			before := lines[0 : index-1]
			after := lines[index:len(lines)]
			before = append(before, update)
			lines = append(before, after...)

			for j := range updates[i].Package.Dependencies.Runtime {
				if strings.HasPrefix(updates[i].Package.Dependencies.Runtime[j], "py3") {
					fmt.Printf("Checking Run Time Dep %s\n", updates[i].Package.Dependencies.Runtime[j])
					//ignore python3 and manual edits files since those yamls done exist
					var depPackage string
					if strings.HasPrefix(updates[i].Package.Dependencies.Runtime[j], "py3") {
						depPackageArr := strings.Split(updates[i].Package.Dependencies.Runtime[j], "-")
						depPackage = depPackageArr[1]
					}

					if updates[i].Package.Dependencies.Runtime[j] != "python3" && !Contains(manualEdits, depPackage) {

						depName := fmt.Sprintf("py%v-%v", pythonVersions[p], depPackage)
						fmt.Printf("Search %v for its updates %v\n", updates[i].Package.Name, depName)

						depFileName := fmt.Sprintf("%s/generated/%s.yaml", cwd, depName)
						data, err := os.ReadFile(depFileName)
						if err != nil {
							fmt.Printf("Error Opening file %s %s \n", yamlFiles[i].Name(), err)

							makefileManualUpdates = append(makefileManualUpdates, depName)
							//os.Exit(1)
						}

						var dataYaml GeneratedMelangeConfig
						err = yaml.Unmarshal(data, &dataYaml)
						if err != nil {
							fmt.Printf("Error unmarshalling %s\n", err)
							makefileManualUpdates = append(makefileManualUpdates, depName)
							//os.Exit(1)
						}

						dep := fmt.Sprintf("$(eval $(call build-package,%v,%v-r0))", depName, dataYaml.Package.Version)

						//add it to the makefile before itself
						before := lines[0 : index-1]
						after := lines[index:len(lines)]
						before = append(before, dep)
						lines = append(before, after...)
					}
				}
			}
		}
		lines[index] =

	}

	newMakefile := strings.Join(lines, "\n")
	data := []byte(newMakefile)
	os.WriteFile(dir+"/Makefile2", data, 0644)
	fmt.Printf("Manual Edits %v\n", manualEdits)

	fmt.Printf("Manual Makefile Edits %v\n", makefileManualUpdates)
}

func Find(a []string, x string) int {
	fmt.Printf("Searching for %v\n", x)
	for i, n := range a {
		if x == n {
			fmt.Printf("Found X at %v\n", i)
			return i
		}
	}
	return len(a)
}

func Contains(list []string, item string) bool {
	for _, v := range list {
		if v == item {
			return true
		}
	}
	return false
}
