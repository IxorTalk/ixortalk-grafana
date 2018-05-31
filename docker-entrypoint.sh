#!/bin/sh
#
#
#  2016 (c) IxorTalk CVBA
#  All Rights Reserved.
#
# NOTICE:  All information contained herein is, and remains
# the property of IxorTalk CVBA
#
# The intellectual and technical concepts contained
# herein are proprietary to IxorTalk CVBA
# and may be covered by U.S. and Foreign Patents,
# patents in process, and are protected by trade secret or copyright law.
#
# Dissemination of this information or reproduction of this material
# is strictly forbidden unless prior written permission is obtained
# from IxorTalk CVBA.
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.
#


# Exit on non-zero return values
set -e

IXORTALK_PROFILE=${IXORTALK_PROFILE:="dev"}
IXORTALK_CONFIG_SERVER_LABEL=${IXORTALK_CONFIG_SERVER_LABEL:="master"}
IXORTALK_CONFIG_SERVER_URL=${IXORTALK_CONFIG_SERVER_URL:="http://ixortalk-config-server:8899/config"}

IXORTALK_CONFIG_SERVER_PATH=${IXORTALK_CONFIG_SERVER_URL}/ixortalk.grafana/${IXORTALK_PROFILE}/${IXORTALK_CONFIG_SERVER_LABEL}

echo "Downloading Grafana Datasource"
curl  -s ${IXORTALK_CONFIG_SERVER_PATH}/grafana-ds.json -o /tmp/grafana-ds.json

echo "Copying grafana dashboard list from ${IXORTALK_CONFIG_SERVER_PATH}"
dashboard_list=$(curl -s ${IXORTALK_CONFIG_SERVER_PATH}/dashboard-list.txt)

echo "Downloading dashboards : \n $dashboard_list"

for dashboard in ${dashboard_list}
do
    curl -s ${IXORTALK_CONFIG_SERVER_PATH}/${dashboard} -o /tmp/${dashboard}
done

echo "Running Grafana "
/run.sh $@ &

echo "Sleeping for 25 seconds to allow Grafana to start (Grafana needs to be up and running to create the datasource / dashboards)"
sleep 25

echo "Creating datasource"
curl -s -H 'Content-Type: application/json' -d @/tmp/grafana-ds.json http://localhost:3000/api/datasources

echo "Creating dashboards"
for dashboard in ${dashboard_list}
do
    curl -s -H 'Content-Type: application/json' -d @/tmp/$dashboard http://localhost:3000/api/dashboards/db
done

echo "Setting default dashboard."
curl -s -X PUT -H 'Content-Type: application/json' -d  '{"theme": "dark","homeDashboardId":1,"timezone":""}'  http://localhost:3000/api/org/preferences

echo "Done .. keeping container alive...."
# Keep container alive
tail -f /dev/null
