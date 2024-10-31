#!/bin/bash

# Script to automatically fix build dependency errors for ActiveMQ project
# Takes commit_ID and module_name as input

commit_ID=$1
module_name=$2
branch_name="temp34_fix_branch"
original_pom="pom.xml"
backup_pom="pom_backup.xml"

# Function to checkout the given commit ID and create a new branch
checkout_commit() {
    echo "Checking out commit: $commit_ID"
    git checkout $commit_ID
    if [ $? -ne 0 ]; then
        echo "Failed to checkout commit $commit_ID"
        exit 1
    fi
    
    # Create a new temporary branch
    echo "Creating a new temporary branch: $branch_name"
    git checkout -b $branch_name
    if [ $? -ne 0 ]; then
        echo "Failed to create branch $branch_name"
        exit 1
    fi
}

# Function to backup the original pom.xml
backup_pom() {
    if [ -f "$original_pom" ]; then
        echo "Backing up original pom.xml to $backup_pom"
        cp "$original_pom" "$backup_pom"
    fi
}

# Function to restore the original pom.xml
restore_pom() {
    if [ -f "$backup_pom" ]; then
        echo "Restoring the original pom.xml"
        mv "$backup_pom" "$original_pom"
    fi
}

# Function to fix the missing xbean-spring dependency
fix_xbean_spring_dependency() {
    echo "Fixing missing xbean-spring dependency..."

    # Check if repository already exists
    if ! grep -q "<id>apache.snapshots</id>" "$original_pom"; then
        echo "Adding Apache's snapshot repository to pom.xml..."
        sed -i '/<\/project>/i\
<repositories>\
    <repository>\
        <id>apache.snapshots</id>\
        <url>https://repository.apache.org/content/repositories/snapshots/</url>\
        <snapshots>\
            <enabled>true</enabled>\
        </snapshots>\
    </repository>\
</repositories>' "$original_pom"
    fi

    # Update xbean-spring dependency to stable version
    echo "Updating xbean-spring dependency to stable version..."
    sed -i '/<artifactId>xbean-spring<\/artifactId>/!b;n;c\    <version>3.9<\/version>' "$original_pom"
}

# Function to fix the missing activeio-core dependency
fix_activeio_core_dependency() {
    echo "Fixing missing activeio-core dependency..."

    # Check if repository already exists
    if ! grep -q "<id>apache.snapshots</id>" "$original_pom"; then
        echo "Adding Apache's snapshot repository to pom.xml..."
        sed -i '/<\/project>/i\
<repositories>\
    <repository>\
        <id>apache.snapshots</id>\
        <url>https://repository.apache.org/content/repositories/snapshots/</url>\
        <snapshots>\
            <enabled>true</enabled>\
        </snapshots>\
    </repository>\
</repositories>' "$original_pom"
    fi

    # Update activeio-core dependency to stable version
    echo "Updating activeio-core dependency to stable version..."
    sed -i '/<artifactId>activeio-core<\/artifactId>/!b;n;c\    <version>3.1.0<\/version>' "$original_pom"
}

# Function to fix the maven-xbean-plugin issue
fix_xbean_plugin_dependency() {
    echo "Fixing missing maven-xbean-plugin..."

    # Update maven-xbean-plugin to stable version
    echo "Updating maven-xbean-plugin to stable version..."
    sed -i '/<artifactId>maven-xbean-plugin<\/artifactId>/!b;n;c\    <version>3.9<\/version>' "$original_pom"
}

# Function to fix the xbean version (if needed)
fix_xbean_version() {
    echo "Fixing xbean-version to stable version..."

    # Update the xbean version from 3.9-SNAPSHOT to stable 3.9
    echo "Updating <xbean-version> in pom.xml..."
    sed -i 's/<xbean-version>3.9-SNAPSHOT<\/xbean-version>/<xbean-version>3.9<\/xbean-version>/' "$original_pom"
}

# Function to compile the module
compile_module() {
    echo "Compiling module: $module_name"
    mvn clean install -DskipTests -pl $module_name -am

    if [ $? -eq 0 ]; then
        echo "Build succeeded!"
        return 0
    else
        echo "Build failed. Checking errors..."
        return 1
    fi
}

# Function to clean up the temporary branch
cleanup_branch() {
    echo "Cleaning up branch: $branch_name"
    git checkout $commit_ID
    git branch -D $branch_name
}

# Main logic
checkout_commit
backup_pom  # Back up the original pom.xml

max_attempts=5
attempt=0

while [ $attempt -lt $max_attempts ]; do
    ((attempt++))
    echo "Attempt #$attempt to compile the module..."

    # Compile the module
    compile_module

    if [ $? -eq 0 ]; then
        echo "Module compiled successfully!"
        restore_pom  # Restore the original pom.xml
        cleanup_branch
        exit 0
    fi

    # If compilation fails, apply fixes for dependencies and xbean version
    echo "Applying fixes for dependencies..."
    fix_xbean_spring_dependency
    fix_activeio_core_dependency
    fix_xbean_plugin_dependency
    fix_xbean_version
done

echo "Failed to compile module after $max_attempts attempts."
restore_pom  # Restore the original pom.xml if it failed
cleanup_branch
exit 1
