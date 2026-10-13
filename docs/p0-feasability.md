#### 1. Working title

Storm Risks for State Hazard Mitigation Planners

#### 2. Audience and need

This project is targeted for hazard mitigation planners at state emergency management agencies who develop and maintain mitigations plans by deciding which hazards to prioritize for mitigation funding. A data product that summarizes event frequency, injuries, and damage done by storms over a recent 10-year window can help to accurately prioritize hazards which in turn might be used to target grant applications and apply funding towards the most frequent/deadly types of storms occuring in that state.

#### 3. Proposed Analytical Product and Questions

An interactive dashboard where the state planner selects their state, then sees hazard types ranked by severity (deaths, injuries, damage costs) with a peer-state comparison view (focusing on the midwest).

Which hazard types account for the largest share of reported deaths and injuries, and the largest share of property and crop damage, in each state over the last 10 years?

How has the annual frequency and total reported damage for the top hazard changed from the first half to the later half of the 10-year window?

How does a state’s reported loss (per-capita) for a given hazard compare with a set of peer states?

#### 4. Source identification and access

Source data name and provider: Severe Storm Event Details | NOAA

Source URL: https://console.cloud.google.com/marketplace/product/noaa-public/severe-storm-events

Project and dataset: bigquery-public-data | noaa_historic_severe_storms

Candidate tables and location: storms_2015, storms_2016, storms_2017, storms_2018, storms_2019, storms_2020, storms_2021, storms_2022, storms_2023, storms_2024, storms_2025 | US

Source approval and accessibility: Confirmed

Terms of service: This dataset is publicly available for anyone to use with no restrictions and is provided "AS IS" without any warranty, express or implied, from Google. Google disclaims all liability for any damages, direct or indirect, resulting from the use of the dataset.

#### 5. Quick source profile

One row equals one event record for one event type in one county over a time span.

Table	        Row Count
storms_2015 	87155
storms_2016 	77291
storms_2017 	81655
storms_2018 	97931
storms_2019 	102613
storms_2020 	85232
storms_2021 	83083
storms_2022 	83338
storms_2023 	91312
storms_2024 	85896
storms_2025 	93203


