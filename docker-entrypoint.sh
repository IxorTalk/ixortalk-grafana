#!/bin/sh
#
# The MIT License (MIT)
#
# Copyright (c) 2016-present IxorTalk CVBA
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
