# CLEUR DevNet-3707 2024

This demo is built to showcase how you AI might assist you in troubleshooting network issues.

The components used by this demo are:

- Virtual IOS-XE devices running ISIS.
  - The [CML Devnet sandbox](https://developer.cisco.com/site/sandbox/) was used to build the lab.
- [ncpeek.](https://github.com/jillesca/ncpeek) A python netconf client used for telegraf.
- TIG stack with docker 20.10+
  - Telegraf grabs telmetry data from network devices.
  - Grafana kicks a webhook when an alarm is detected.
- FastAPI.
  - Host the LLM.
  - Interacts with network devices & frontend.
- PyATS. Provides a framework to interact with network devices.
- [Webex_bot](https://github.com/fbradyirl/webex_bot) use to interact with the LLM.
- OpenAI LLM.
  - `gpt-4-turbo-preview` was used.

## Demo

For this demo [one alarm was created.](grafana/alerts.yaml)

When the average number of ISIS neighbors in a lapse of 30 second _**is less than**_ the average number of ISIS neighbors in a lapse of 30 minutes, the alarm will trigger a webhook for the LLM.

This signal that a stable ISIS neighbor that was working on the last 30 minutes was lost, and allows to work with `N` number of ISIS neighbors.

## Prepare Demo

### Environment variables

#### Mandatory variables

For the demo to work, you **must** set the next environment variables. You can either `export` the environment variables or create a `.env` file with them. See [.env.local](.env.local) for an example.

```bash
OPENAI_API_KEY=<YOUR_OPENAI_API_KEY>
WEBEX_TEAMS_ACCESS_TOKEN=<YOUR_TEAM_ACCESS_TOKEN>
WEBEX_APPROVED_USERS_MAIL=<MAILS_OF_USERS_APPROVED_SEPARATED_BY_COMMAS>
WEBEX_USERNAME=<YOUR_WEBEX_USERNAME>
WEBEX_ROOM_ID=<THE_WEBEX_ROOM_ID>
```

> _**NOTE:**_ The webex variables are only needed if you interact with the LLM using webex.

If you prefer to use another client, you need to:

- Modify the [notify function](llm_agent/app.py#L59) to accomodate your client.
- Remove/comment [the start of the webex bot](llm_agent/app.py#L73)
- Communicate with the LLM using REST API. See [send_message_to_chat_api](llm_agent/webex_chat/chat_api_client.py#L13) for an example.

##### Webex considerations

To get your webex token go to <https://developer.webex.com/docs/bots> and create a bot.

To get the `WEBEX_ROOM_ID` the easiest way is to open a room with your bot in the webex app. Once you have your room, you can get the `WEBEX_ROOM_ID` by using [API list room](https://developer.webex.com/docs/api/v1/rooms/list-rooms) use your token created before.

#### Optional Variables

For testing, you can use the `GRAFANA_WEB_HOOK` env var to send webhooks to other site, such as <https://webhook.site/>

If you have access to smith.langchain.com (recommended for view LLM operations) add your project ID and API key.

```bash
GRAFANA_WEB_HOOK=<WEB_HOOK_URL>
LANGCHAIN_PROJECT=<YOUR_LANGCHAIN_PROJECT_ID>
LANGCHAIN_API_KEY=<YOUR_LANGCHAIN_API_KEY>
LANGCHAIN_TRACING_V2=true
LANGCHAIN_ENDPOINT=https://api.smith.langchain.com
```

### TIG Stack

- Import the [topology file to CML](cml/topology.yaml) and start the network.
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

The [llm_agent directory](llm_agent/) provides all the code used to run the LLM.

On the demo, the LLM ran using a python virtual environment. Make sure to install the [requirementes listed.](llm_agent/requirements.txt)

The entry point for the application is the [app file](llm_agent/app.py)

_**NOTE:** In the upcoming weeks, a container will be added for the LLM_

## Test the Demo

![network topology](/img/cml.png)

The demo presented consisted on shutting down one interface, make ISIS fail, and let the LLM figure it out what happened and how to fix it.

In the images below, `GigabitEthernet5` was shutting down on `cat8000-v0` resulting in losing its ISIS adjacency with `cat8000-v2`

On grafana you can observe the ISIS counting going down and triggering the alarm.

![grafana alarm](img/grafana1.png)
![grafana alarm 2](img/grafana2.png)

Next, you will receive a webex notification from grafana and the LLM will receive the webhook. The webhook triggers the LLM to start looking at what the issue is and how to resolve it.

![llm thinking 1](img/webex_bot1.png)
![llm thinking 2](img/webex_bot2.png)
![llm thinking 3](img/webex_bot3.png)
![llm thinking 4](img/webex_bot4.png)
![llm thinking 5](img/webex_bot5.png)
![llm thinking 6](img/webex_bot6.png)

## Notes

- You can easily run out of OpenAI 4k tokens in your replies from netconf, so is important to filter data to what AI could need.
- Repeated alarms are suppresed by Grafana, this is controlled by [the grafana policy file,](grafana/config/policies.yaml)
  - If you are testing continously, run `./build_run_grafana.sh` to destroy and create the container.
  - Not an ideal scenario, but wasn't able to find a proper solution on the time given.
- From time to time, the answers from the LLM are lost and not sent to webex. You can find them on the terminal output.
- This is the second iteration of this exercise. The first one was [presented at Cisco Impact 2023](https://github.com/jillesca/open_telemetry_network_impact)
