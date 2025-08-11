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

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L1103
#Job: {
	Region:    string | *"global"
	Namespace: string | *"default"
	ID:        string
	Name:      string | *ID
	Type:      *"service" | "system" | "batch" | "sysbatch"
	Priority:  (int & >=1 & <=100) | *50
	AllAtOnce: bool | *false
	Datacenters: [...string] | *null
	Constraints: [...#Constraint] | *null
	Update:   #UpdateStrategy | *null
	Periodic: #PeriodicConfig | *null
	Migrate:  #MigrateStrategy | *null

	TaskGroups: [...(_#TaskGroupWithDefaults & {in: {
		JobName: Name
		JobType: Type
	}}).out]
}

// UpdateStrategy defines a task groups update strategy.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L621-L631
#UpdateStrategy: {
	Stagger:          int64 | *(30 * time.Second)
	MaxParallel:      uint | *1
	HealthCheck:      *"checks" | "task_states" | "manual"
	MinHealthyTime:   int64 | *(10 * time.Second)
	HealthyDeadline:  int64 | *(5 * time.Minute)
	ProgressDeadline: int64 | *(10 * time.Minute)
	Canary:           uint | *0
	AutoRevert:       bool | *false
	AutoPromote:      bool | *false
}

// PeriodicConfig is for serializing periodic config for a job.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/jobs.go#L895-L903
#PeriodicConfig: {
	Enabled: bool | *true
	Spec:    string | *""
	Specs: [...string]
	SpecType:        "cron"
	ProhibitOverlap: bool | *false
	TimeZone:        (string & !="") | *"UTC"
}
