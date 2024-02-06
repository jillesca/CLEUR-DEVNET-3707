# ai-agent-for-network-issues

### Verify telemetry on Telegraf, Influxdb, Grafana

- telegraf - `docker exec -it telegraf bash` > [tail -F /tmp/telegraf-grpc.log](telegraf/dockerfile#L30)
- Influxdb - <http://localhost:8086> admin/admin123
- Grafana - <http://localhost:3000/dashboards> admin/admin
  - General > Network Telemetry

## Test the Demo

Start by shutting down an ISIS interface in any cat8000v, in this case `GigabitEthernet 2`

![shutdown G2](img/cat8kv_interface_shutdown.png)

You will see a drop in the grafana dashboard for these metrics, and the alarms will be fired and you will receive a webook on the chatbot.

<http://localhost:3000/dashboards> General > Network Telemetry

![grafana dashboard](img/grafana_dashboard_alerted.png)

<http://localhost:3000/alerting/list>

![grafana alerts](img/grafana_alerts_firing.png)

After a few seconds the AI will receive a webhook, will analyse it and notify you about what happened. Suggesting some actions and tell you a joke to relax a bit.

Currently, it will process every webhook receive and will try to see if the alarms can be related.

## Notes

You can easily run out of OpenAI 4k tokens in your replies from netconf, so is important to filter data to what AI could need.
