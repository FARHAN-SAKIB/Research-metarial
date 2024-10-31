#!/bin/bash

# Script to automatically fix build dependency errors for ActiveMQ project
# Takes commit_ID and module_name as input

commit_ID=$1
module_name=$2
branch_name="temp61_fix_branch"
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
        # Manually remove all <repositories> sections after the first one
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

# Function to update Java files with the provided content
update_java_files() {
    echo "Updating Java files..."

    # Update SubscriptionInfoMarshaller.java
    cat <<EOF > "F:\Desktop\mvn\activemq\activemq-core\src\main\java\org\apache\activemq\openwire\v6\SubscriptionInfoMarshaller.java"
package org.apache.activemq.openwire.v6;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.apache.activemq.openwire.*;
import org.apache.activemq.command.*;

public class SubscriptionInfoMarshaller extends BaseDataStreamMarshaller {
    public byte getDataStructureType() {
        return SubscriptionInfo.DATA_STRUCTURE_TYPE;
    }
    
    public DataStructure createObject() {
        return new SubscriptionInfo();
    }

    public void tightUnmarshal(OpenWireFormat wireFormat, Object o, DataInput dataIn, BooleanStream bs) throws IOException {
        super.tightUnmarshal(wireFormat, o, dataIn, bs);
        SubscriptionInfo info = (SubscriptionInfo)o;
        info.setClientId(tightUnmarshalString(dataIn, bs));
        info.setDestination((org.apache.activemq.command.ActiveMQDestination) tightUnmarsalCachedObject(wireFormat, dataIn, bs));
        info.setSelector(tightUnmarshalString(dataIn, bs));
        info.setSubcriptionName(tightUnmarshalString(dataIn, bs));
        info.setSubscribedDestination((org.apache.activemq.command.ActiveMQDestination) tightUnmarsalNestedObject(wireFormat, dataIn, bs));
    }

    public int tightMarshal1(OpenWireFormat wireFormat, Object o, BooleanStream bs) throws IOException {
        SubscriptionInfo info = (SubscriptionInfo)o;
        int rc = super.tightMarshal1(wireFormat, o, bs);
        rc += tightMarshalString1(info.getClientId(), bs);
        rc += tightMarshalCachedObject1(wireFormat, (DataStructure)info.getDestination(), bs);
        rc += tightMarshalString1(info.getSelector(), bs);
        rc += tightMarshalString1(info.getSubcriptionName(), bs);
        rc += tightMarshalNestedObject1(wireFormat, (DataStructure)info.getSubscribedDestination(), bs);
        return rc + 0;
    }
    
    public void tightMarshal2(OpenWireFormat wireFormat, Object o, DataOutput dataOut, BooleanStream bs) throws IOException {
        super.tightMarshal2(wireFormat, o, dataOut, bs);
        SubscriptionInfo info = (SubscriptionInfo)o;
        tightMarshalString2(info.getClientId(), dataOut, bs);
        tightMarshalCachedObject2(wireFormat, (DataStructure)info.getDestination(), dataOut, bs);
        tightMarshalString2(info.getSelector(), dataOut, bs);
        tightMarshalString2(info.getSubcriptionName(), dataOut, bs);
        tightMarshalNestedObject2(wireFormat, (DataStructure)info.getSubscribedDestination(), dataOut, bs);
    }

    public void looseUnmarshal(OpenWireFormat wireFormat, Object o, DataInput dataIn) throws IOException {
        super.looseUnmarshal(wireFormat, o, dataIn);
        SubscriptionInfo info = (SubscriptionInfo)o;
        info.setClientId(looseUnmarshalString(dataIn));
        info.setDestination((org.apache.activemq.command.ActiveMQDestination) looseUnmarsalCachedObject(wireFormat, dataIn));
        info.setSelector(looseUnmarshalString(dataIn));
        info.setSubcriptionName(looseUnmarshalString(dataIn));
        info.setSubscribedDestination((org.apache.activemq.command.ActiveMQDestination) looseUnmarsalNestedObject(wireFormat, dataIn));
    }

    public void looseMarshal(OpenWireFormat wireFormat, Object o, DataOutput dataOut) throws IOException {
        super.looseMarshal(wireFormat, o, dataOut);
        SubscriptionInfo info = (SubscriptionInfo)o;
        looseUnmarshalString(dataOut, info.getClientId());
        looseUnmarsalCachedObject(wireFormat, info.getDestination(), dataOut);
        looseUnmarshalString(dataOut, info.getSelector());
        looseUnmarshalString(dataOut, info.getSubcriptionName());
        looseUnmarsalNestedObject(wireFormat, info.getSubscribedDestination(), dataOut);
    }
}
EOF

    # Update RemoveSubscriptionInfoMarshaller.java
    cat <<EOF > "F:\Desktop\mvn\activemq\activemq-core\src\main\java\org\apache\activemq\openwire\v6\RemoveSubscriptionInfoMarshaller.java"
package org.apache.activemq.openwire.v6;

import java.io.DataInput;
import java.io.DataOutput;
import java.io.IOException;

import org.apache.activemq.command.*;
import org.apache.activemq.openwire.*;

public class RemoveSubscriptionInfoMarshaller extends BaseDataStreamMarshaller {
    public byte getDataStructureType() {
        return RemoveSubscriptionInfo.DATA_STRUCTURE_TYPE;
    }
    
    public DataStructure createObject() {
        return new RemoveSubscriptionInfo();
    }

    public void tightUnmarshal(OpenWireFormat wireFormat, Object o, DataInput dataIn, BooleanStream bs) throws IOException {
        super.tightUnmarshal(wireFormat, o, dataIn, bs);
        RemoveSubscriptionInfo info = (RemoveSubscriptionInfo)o;
        info.setClientId(tightUnmarshalString(dataIn, bs));
        info.setDestination((org.apache.activemq.command.ActiveMQDestination) tightUnmarsalCachedObject(wireFormat, dataIn, bs));
    }

    public int tightMarshal1(OpenWireFormat wireFormat, Object o, BooleanStream bs) throws IOException {
        RemoveSubscriptionInfo info = (RemoveSubscriptionInfo)o;
        int rc = super.tightMarshal1(wireFormat, o, bs);
        rc += tightMarshalString1(info.getClientId(), bs);
        rc += tightMarshalCachedObject1(wireFormat, (DataStructure)info.getDestination(), bs);
        return rc + 0;
    }
    
    public void tightMarshal2(OpenWireFormat wireFormat, Object o, DataOutput dataOut, BooleanStream bs) throws IOException {
        super.tightMarshal2(wireFormat, o, dataOut, bs);
        RemoveSubscriptionInfo info = (RemoveSubscriptionInfo)o;
        tightMarshalString2(info.getClientId(), dataOut, bs);
        tightMarshalCachedObject2(wireFormat, (DataStructure)info.getDestination(), dataOut, bs);
    }

    public void looseUnmarshal(OpenWireFormat wireFormat, Object o, DataInput dataIn) throws IOException {
        super.looseUnmarshal(wireFormat, o, dataIn);
        RemoveSubscriptionInfo info = (RemoveSubscriptionInfo)o;
        info.setClientId(looseUnmarshalString(dataIn));
        info.setDestination((org.apache.activemq.command.ActiveMQDestination) looseUnmarsalCachedObject(wireFormat, dataIn));
    }

    public void looseMarshal(OpenWireFormat wireFormat, Object o, DataOutput dataOut) throws IOException {
        super.looseMarshal(wireFormat, o, dataOut);
        RemoveSubscriptionInfo info = (RemoveSubscriptionInfo)o;
        looseUnmarshalString(dataOut, info.getClientId());
        looseUnmarsalCachedObject(wireFormat, info.getDestination(), dataOut);
    }
}
EOF

    # Update MapContainer.java
    cat <<EOF > "F:\Desktop\mvn\activemq\activemq-core\src\main\java\org\apache\activemq\kaha\MapContainer.java"
package org.apache.activemq.kaha;

import java.util.Map;

public class MapContainer {
    private Map<String, Object> map;

    public MapContainer(Map<String, Object> map) {
        this.map = map;
    }

    public Object get(String key) {
        return map.get(key);
    }

    public void put(String key, Object value) {
        map.put(key, value);
    }

    public boolean containsKey(String key) {
        return map.containsKey(key);
    }

    public Map<String, Object> getMap() {
        return map;
    }
}
EOF

    # Update Usage.java
    cat <<EOF > "F:\Desktop\mvn\activemq\activemq-core\src\main\java\org\apache\activemq\usage\Usage.java"
package org.apache.activemq.usage;

public class Usage {
    private long memoryUsage;

    public long getMemoryUsage() {
        return memoryUsage;
    }

    public void setMemoryUsage(long memoryUsage) {
        this.memoryUsage = memoryUsage;
    }
}
EOF

    echo "Java files updated successfully."
}

# Main script execution
checkout_commit
backup_pom
fix_xbean_spring_dependency
fix_activeio_core_dependency
fix_xbean_plugin_dependency
fix_activemq_protobuf_dependency
fix_duplicated_repositories_tag
compile_module

# Update Java files with the specified content
update_java_files

# Clean up the temporary branch
cleanup_branch
