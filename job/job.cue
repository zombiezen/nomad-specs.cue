// Copyright 2025 Roxy Light
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0

package job

import "time"

// A Job is a declarative specification of tasks that Nomad should run.
// https://developer.hashicorp.com/nomad/docs/job-specification/job
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L1102-L1126
#Job: {
	let taskGroup = (_#TaskGroupWithDefaults & {in: {
		JobName: Name
		JobType: Type
	}}).out

	Region:    string | *"global"
	Namespace: string | *"default"
	ID:        string
	Name:      string | *ID
	Type:      *"service" | "system" | "batch" | "sysbatch"
	Priority:  (int & >=1 & <=100) | *50
	AllAtOnce: bool | *false
	Datacenters: [...string] | *["*"]
	NodePool: string | *"default"
	Constraints: [...#Constraint]
	Affinities: [...#Affinity]
	TaskGroups: [taskGroup, ...taskGroup]
	Update:      #UpdateStrategy | *null
	Multiregion: #Multiregion | *null
	Spreads: [...#Spread]
	Periodic:         #PeriodicConfig | *null
	ParameterizedJob: #ParameterizedJobConfig | *null
	Reschedule:       #ReschedulePolicy | null
	Migrate:          #MigrateStrategy | *null
	Meta: {[string]: string}
	UI: #JobUIConfig | *null

	let defaultReschedulePolicy = #DefaultReschedulePolicy[Type]
	if defaultReschedulePolicy == null {
		Reschedule: null
	}
	if defaultReschedulePolicy != null {
		Reschedule: #ReschedulePolicy & {
			for k, v in #ReschedulePolicy {"\(k)": v | *(defaultReschedulePolicy[k])}
		}
	}
	if Type == "batch" || Type == "sysbatch" {
		Update:  null
		Migrate: null
	}
}

// UpdateStrategy defines a task groups update strategy.
// https://developer.hashicorp.com/nomad/docs/job-specification/update
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L621-L631
#UpdateStrategy: {
	Stagger:          #Duration | *(30 * time.Second)
	MaxParallel:      uint | *1
	HealthCheck:      *"checks" | "task_states" | "manual"
	MinHealthyTime:   #Duration | *(10 * time.Second)
	HealthyDeadline:  #Duration | *(5 * time.Minute)
	ProgressDeadline: #Duration | *(10 * time.Minute)
	Canary:           uint | *0
	AutoRevert:       bool | *false
	AutoPromote:      bool | *false
}

// https://developer.hashicorp.com/nomad/docs/job-specification/multiregion
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L822-L825
#Multiregion: {
	Strategy: #MultiregionStrategy
	Regions: [...#MultiregionRegion]
}

// https://developer.hashicorp.com/nomad/docs/job-specification/multiregion#strategy-parameters
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L882-L885
#MultiregionStrategy: {
	MaxParallel: int | *0
	OnFailure:   *"" | "fail_all" | "fail_local"
}

// https://developer.hashicorp.com/nomad/docs/job-specification/multiregion#region-parameters
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L887-L893
#MultiregionRegion: {
	Name:  string
	Count: uint | *1
	Datacenters: [...string]
	NodePool: string | *""
	Meta: {[string]: string}
}

// PeriodicConfig is for serializing periodic config for a job.
// https://developer.hashicorp.com/nomad/docs/job-specification/periodic
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L895-L903
#PeriodicConfig: {
	Enabled: bool | *true
	Specs: [...string]
	SpecType:        "cron"
	ProhibitOverlap: bool | *false
	TimeZone:        (string & !="") | *"UTC"
}

// A ParameterizedJobConfig is used to encapsulate a set of work
// that can be carried out on various inputs much like a function definition.
// https://developer.hashicorp.com/nomad/docs/job-specification/parameterized
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L978-L983
#ParameterizedJobConfig: {
	Payload: *"optional" | "required" | "forbidden"
	MetaRequired: [...string]
	MetaOptional: [...string]
}

// https://developer.hashicorp.com/nomad/docs/job-specification/ui
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L1008-L1011
#JobUIConfig: {
	Description: string | *""
	Links: [...#JobUILink]
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L1013-L1016
#JobUILink: {
	Label: string
	URL:   string
}

#Duration: int64
