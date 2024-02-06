# CLEUR DevNet-3707 2024

This demo is built to showcase how you might AI to assist you in troubleshooting issues.

The components used by this demo are:

- Virtual IOS-XE devices running ISIS.
  - The [CML Devnet sandbox](https://developer.cisco.com/site/sandbox/) was used to build the lab.
- [ncpeek.](https://github.com/jillesca/ncpeek) A python netconf client used by telegraf.
- TIG stack with docker 20.10+
  - Telegraf grabs telmetry data from network devices.
  - Grafana kicks a webhook when an alarm is detected.
- FastAPI.
  - Host the LLM.
  - Interacts with network devices & frontend.
- PyATS. Provides a framework to interact with network devices.
- [Webex_bot](https://github.com/fbradyirl/webex_bot) use to interact with the LLM.
- OpenAI LLM.

## Demo

For this demo [one alarm was created.](grafana/alerts.yaml) When the averga of number of ISIS neighbors in 30 second is less than the average in 30 minutes, the alarm will trigger. This allows to work with `N` number of ISIS neighbors.

## Prepare Demo

### Environment variables

For the demo to work correctly, you **must** set the next environment variables.

```bash
OPENAI_API_KEY
WEBEX_TEAMS_ACCESS_TOKEN
WEBEX_APPROVED_USERS_MAIL
WEBEX_USERNAME
WEBEX_ROOM_ID
```

The webex API is only needed if you want to interact with webex as the demo is built. If you prefer to use another client, you need to adapt the code.

To work with a bot on webex and get your API keys, go to <https://developer.webex.com/docs/bots>

Optional environment variables:

```bash
LANGCHAIN_PROJECT
LANGCHAIN_API_KEY
LANGCHAIN_TRACING_V2=true
LANGCHAIN_ENDPOINT=https://api.smith.langchain.com
```

### TIG Stack

- Import the [topology file to CML](cml/topology.yaml)
- Start the TIG start
  - `./build_run_telegraf.sh`
  - `./build_run_influxdb.sh`
  - `./build_run_grafana.sh`

#### Verify telemetry on Telegraf, Influxdb, Grafana

- telegraf - `docker exec -it telegraf bash` > [tail -F /tmp/telegraf-grpc.log](telegraf/dockerfile#L30)
- Influxdb - <http://localhost:8086> admin/admin123
- Grafana - <http://localhost:3000/dashboards> admin/admin
  - General > Network Telemetry

### Start the LLM

The [llm_agent dirctory](llm_agent/) provides all the code used to run the LLM.

On the demo, this was run using a python virtual environment. Make sure to install the [requirementes listed.](llm_agent/requirements.txt)

Then run the LLM by executing the [app file](llm_agent/app.py)

_**NOTE:** In the upcoming weeks, a container will be added for the LLM_

## Test the Demo

![network topology](/img/cml.png)

The demo presented consisted on shutting down one interface, make isis fail, and let the LLM figure it out what happened and how to fix it.

In the images below, GigabitEthernet5 was shutting down on `cat8000-v0` resulting in losing its ISIS adjacency with `cat8000-v2`

On grafana you can observe the isis counting going down and triggering the alarm.

![grafana alarm](img/grafana1.png)
![grafana alarm 2](img/grafana2.png)

Next the LLM will start looking at what the issue is and how to resolve it.

![llm thinking 1](img/webex_bot1.png)
![llm thinking 2](img/webex_bot2.png)
![llm thinking 3](img/webex_bot3.png)
![llm thinking 4](img/webex_bot4.png)
![llm thinking 5](img/webex_bot5.png)
![llm thinking 6](img/webex_bot6.png)

## Notes

- You can easily run out of OpenAI 4k tokens in your replies from netconf, so is important to filter data to what AI could need.
- Repeated alarms are suppresed by Grafana, this is control on [the grafana policy file,](grafana/config/policies.yaml)
  - If you are testing continously, run `./build_run_grafana.sh` to distroy and create the container.
  - Not ideal scenario, but wasn't able to find a proper solution.
