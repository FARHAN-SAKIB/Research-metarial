#!/bin/bash

# Script to automatically fix build dependency errors for ActiveMQ project
# Takes commit_ID, module_name, and Java version as input

commit_ID=$1
module_name=$2
java_version=$3
branch_name="temp61001_fix_branch"
original_pom="pom.xml"
backup_pom="pom_backup.xml"

# Function to set the required Java version
set_java_version() {
    echo "Setting Java version to $java_version..."

    # Define the paths for different Java versions
    case "$java_version" in
        "8")
            export JAVA_HOME="/c/Program Files/Java/jdk1.8.0_202"
            ;;
        "11")
            export JAVA_HOME="/c/Program Files/Java/jdk-11"
            ;;
        "17")
            export JAVA_HOME="/c/Program Files/Java/jdk-17"
            ;;
        "20")
            export JAVA_HOME="/c/Program Files/Java/jdk-20"
            ;;
        *)
            echo "Unsupported Java version specified. Please use 8, 11, 17, or 20."
            exit 1
            ;;
    esac

    # Update PATH to use the selected Java version
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME set to $JAVA_HOME"
    echo "Java version set to $("$JAVA_HOME/bin/java" -version 2>&1 | head -n 1)"
}

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

# Function to fix non-resolvable parent POM issue
fix_non_resolvable_parent_pom() {
    echo "Attempting to fix non-resolvable parent POM issue..."

    # Force update Maven dependencies
    echo "Forcing update of Maven dependencies..."
    mvn clean install -U -DskipTests

    # Ensure parent POM is correctly defined or provide local installation instructions
    echo "Checking if parent POM is locally resolvable..."
    if ! mvn validate; then
        echo "Parent POM not found. Trying to install manually..."
    fi
}

# Function to fix missing activemq-ra dependency
fix_activemq_ra_dependency() {
    echo "Fixing missing activemq-ra dependency..."

    # Add repository if not already present
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

    # Update activemq-ra dependency to stable version
    echo "Updating activemq-ra dependency to stable version..."
    sed -i '/<artifactId>activemq-ra<\/artifactId>/!b;n;c\    <version>5.4.0<\/version>' "$original_pom"
}

# Function to fix the missing xbean-spring dependency
fix_xbean_spring_dependency() {
    echo "Fixing missing xbean-spring dependency..."

    # Add repository if not already present
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

    # Add repository if not already present
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

# Function to fix the activemq-protobuf issue
fix_activemq_protobuf_dependency() {
    echo "Fixing missing activemq-protobuf dependency..."

    # Add Apache snapshot repository configuration if not already present
    if ! grep -q "<id>apache.snapshots</id>" "$original_pom"; then
        echo "Adding Apache's snapshot repository to pom.xml..."
        sed -i '/<\/project>/i\
<repositories>\
    <repository>\
        <id>apache.snapshots</id>\
        <url>https://repository.apache.org/content/repositories/snapshots/</url>\
        <releases>\
            <enabled>false</enabled>\
        </releases>\
        <snapshots>\
            <enabled>true</enabled>\
        </snapshots>\
    </repository>\
</repositories>' "$original_pom"
    fi

    # Update activemq-protobuf dependency to stable version
    echo "Updating activemq-protobuf dependency to stable version..."
    sed -i '/<artifactId>activemq-protobuf<\/artifactId>/!b;n;c\    <version>1.0<\/version>' "$original_pom"
}

# Function to fix duplicated repositories tag
fix_duplicated_repositories_tag() {
    echo "Checking for duplicated <repositories> tag..."

    duplicated_tag_count=$(grep -c "<repositories>" "$original_pom")

    if [ "$duplicated_tag_count" -gt 1 ]; then
        echo "Duplicated <repositories> tag found. Removing extra ones..."
        first_repo_position=$(grep -n "<repositories>" "$original_pom" | head -n 1 | cut -d: -f1)
        sed -i "$(("$first_repo_position" + 1)),\$s/<repositories>.*<\/repositories>/<!-- Duplicated repositories removed -->/" "$original_pom"
    else
        echo "No duplicated <repositories> tag found."
    fi
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

# Function to detect missing plugin versions and attempt automatic fix
fix_missing_plugin_versions() {
    echo "Detecting and fixing missing plugin versions..."

    # Fixing common missing plugin versions
    mvn versions:display-plugin-updates | grep -A 2 "Plugin Plugin version"
    mvn versions:use-latest-versions
}

# Main logic
set_java_version              # Set the specified Java version
checkout_commit
backup_pom                    # Back up the original pom.xml

max_attempts=1
attempt=0

while [ $attempt -lt $max_attempts ]; do
    ((attempt++))
    echo "Attempt #$attempt to compile the module..."

    # Compile the module
    compile_module

    if [ $? -eq 0 ]; then
        echo "Module compiled successfully!"
        restore_pom             # Restore the original pom.xml
        cleanup_branch
        exit 0
    fi

    # If compilation fails, apply fixes for dependencies
    echo "Applying fixes for dependencies..."
    fix_duplicated_repositories_tag  # New step to fix duplicated repositories
    fix_non_resolvable_parent_pom    # New step to fix non-resolvable parent POM
    fix_activemq_ra_dependency       # New step to fix missing activemq-ra dependency
    fix_xbean_spring_dependency
    fix_activeio_core_dependency
    fix_xbean_plugin_dependency
    fix_activemq_protobuf_dependency
    fix_missing_plugin_versions      # New step for plugin fixes
done

restore_pom                    # Restore the original pom.xml if all attempts fail
echo "Unable to fix build errors after $max_attempts attempts."
cleanup_branch
exit 1
