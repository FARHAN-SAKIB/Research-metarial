#!/bin/bash

# Prompt the user for Commit_ID and Module
read -p "Enter Commit ID: " commit_id
read -p "Enter Module Name: " module_name

# Define the log directory
log_directory="F:/Desktop/mvn/activemq/Module_Compilation/jdk8"

# Create the directory if it doesn't exist
mkdir -p "${log_directory}"

# Create a log file name in the format jdk20_Commit_ID(Module).log (just the filename for the CSV)
log_file_name="jdk8_${commit_id}(${module_name}).log"
log_file="${log_directory}/${log_file_name}"

# Define the CSV file location in the Dataset directory
csv_file="F:/Desktop/mvn/apex-core/Module_Compilation/Dataset/compile_module.csv"

# Check if the CSV file exists; if not, create it with a header
if [ ! -f "${csv_file}" ]; then
  echo "Commit_ID,Module_Name,Java_Version,Build_Status,Project_Name,Log_File" > "${csv_file}"
fi

# Retrieve the Java version
java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')

# Get the project name or Git URL
project_name=$(git config --get remote.origin.url)

# Checkout the specified commit and log the output
echo "Checking out commit ${commit_id}..." | tee -a "${log_file}"
git checkout "${commit_id}" >> "${log_file}" 2>&1

# Check if the checkout was successful
if [ $? -ne 0 ]; then
  echo "Git checkout failed. See the log for details." | tee -a "${log_file}"
  build_status="Failure"
  echo "${commit_id},${module_name},${java_version},${build_status},${project_name},${log_file_name}" >> "${csv_file}"
  exit 1
fi

# Run the Maven command and redirect the output to the log file
echo "Running Maven build for module '${module_name}'..." | tee -a "${log_file}"
mvn clean install -DskipTests -pl "${module_name}" -am >> "${log_file}" 2>&1

# Check if the Maven build was successful
if [ $? -ne 0 ]; then
  echo "Maven build failed. See the log for details." | tee -a "${log_file}"
  build_status="Failure"
else
  echo "Maven build succeeded." | tee -a "${log_file}"
  build_status="Success"
fi

# Append the result to the CSV file, including the log file name (without full path)
echo "${commit_id},${module_name},${java_version},${build_status},${project_name},${log_file_name}" >> "${csv_file}"

# Notify the user that the script has completed
echo "Maven build for module '${module_name}' at commit '${commit_id}' has been logged in '${log_file}'."
