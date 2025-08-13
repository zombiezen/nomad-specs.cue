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

// https://developer.hashicorp.com/nomad/docs/job-specification/restart
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L98-L106
#RestartPolicy: {
	Interval:        #Duration
	Attempts:        uint
	Delay:           #Duration | *(15 * time.Second)
	Mode:            *"fail" | "delay"
	RenderTemplates: bool | *false
}

#DefaultRestartPolicy: {
	[#Job.Type]: #RestartPolicy

	// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L649-L657
	let servicePolicy = {
		Delay:           15 * time.Second
		Attempts:        2
		Interval:        30 * time.Minute
		Mode:            "fail"
		RenderTemplates: false
	}

	// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L661-L669
	let batchPolicy = {
		Delay:           15 * time.Second
		Attempts:        3
		Interval:        24 * time.Hour
		Mode:            "fail"
		RenderTemplates: false
	}

	service:  servicePolicy
	system:   servicePolicy
	batch:    batchPolicy
	sysbatch: batchPolicy
}

// DisconnectStrategy defines how both clients and server should behave
// in case of disconnection between them.
// https://developer.hashicorp.com/nomad/docs/job-specification/disconnect
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L126-L145
#DisconnectStrategy: {
	Replace:   bool | *false
	Reconcile: "keep_original" | "keep_replacement" | *"best_score" | "longest_running"

	{LostAfter: #Duration & >=0} |
	{StopOnClientAfter: #Duration & >=0}
}

// https://developer.hashicorp.com/nomad/docs/job-specification/reschedule
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L157-L178
#ReschedulePolicy: {
	// TODO(maybe): Nomad allows groups to pass partial fields and those will be merged with the job policy.
	// CUE lets us do this more cleanly, so I'd prefer to specify the whole object.

	Attempts:      uint
	Interval:      #Duration
	Delay:         #Duration
	DelayFunction: "" | "constant" | "exponential" | "fibonacci"
	MaxDelay:      #Duration
	Unlimited:     bool
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L257-L309
#DefaultReschedulePolicy: {
	[#Job.Type]: #ReschedulePolicy | null

	"service": {
		Delay:         30 * time.Second
		DelayFunction: "exponential"
		MaxDelay:      1 * time.Hour
		Unlimited:     true

		Attempts: 0
		Interval: 0
	}

	"batch": {
		Attempts:      1
		Interval:      24 * time.Hour
		Delay:         5 * time.Second
		DelayFunction: "constant"

		MaxDelay:  0
		Unlimited: false
	}

	[_ & !="service" & !="batch"]: null
}

// The Affinity block allows operators to express placement preference for a set of nodes.
// https://developer.hashicorp.com/nomad/docs/job-specification/affinity
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L226-L232
#Affinity: {
	// LTarget is the name or reference of the attribute to examine for the affinity.
	LTarget: string
	// RTarget is the value to compare the attribute against using the specified operation.
	RTarget: string
	Operand: *"=" | "!=" | ">" | ">=" | "<=" | "regexp" | "set_contains_all" | "set_contains_any" | "version"
	// Weight applied to nodes that match the affinity. Can be negative.
	Weight: (int & >=-100 & <=100) | *50
}

// The Spread block allows operators to increase the failure tolerance of their applications
// by specifying a node attribute that allocations should be spread over.
// https://developer.hashicorp.com/nomad/docs/job-specification/spread
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L330-L335
#Spread: {
	Attribute: string
	Weight:    (int & >=0 & <=100) | *0
	SpreadTarget: [#SpreadTarget, ...#SpreadTarget] | *null
}

// https://developer.hashicorp.com/nomad/docs/job-specification/spread#target-parameters
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L337-L341
#SpreadTarget: {
	Value:   string
	Percent: (int & >=0 & <=100) | *0
}

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L496-L523
#TaskGroup: {
	Name:  string
	Count: uint
	Constraints: [...#Constraint]
	Affinities: [...#Affinity]
	Tasks: [#Task, ...#Task]
	Spreads: [...#Spread]
	Volumes: {[label=string]: #VolumeRequest & {Name: label}}
	RestartPolicy:    #RestartPolicy
	Disconnect:       #DisconnectStrategy | *null
	ReschedulePolicy: #ReschedulePolicy | *null
	EphemeralDisk:    #EphemeralDisk
	Update:           #UpdateStrategy | *null
	Migrate:          #MigrateStrategy | *null
	Networks: [...#NetworkResource]
	Meta: {[string]: string}
	Services: [...#Service]
	ShutdownDelay: #Duration | *0
	Scaling:       #ScalingPolicy | *null
	Consul:        #Consul | *null

	if Scaling == null {
		Count: uint | *1
	}
	if Scaling != null {
		Count: uint | *(Scaling.Min)
	}
}

_#TaskGroupWithDefaults: {
	X=in: {
		JobName: string
		JobType: "service" | "system" | "batch" | "sysbatch"
	}

	out: #TaskGroup & {
		groupName=Name: _

		Services: [...(_#ServiceWithDefaults & {in: {
			JobName:   X.JobName
			GroupName: groupName
		}}).out]

		Tasks: [...(_#TaskWithDefaults & {in: {
			JobName:   X.JobName
			GroupName: groupName
		}}).out]

		RestartPolicy: #RestartPolicy & {
			for k, v in #RestartPolicy {"\(k)": v | *(#DefaultRestartPolicy[X.JobType][k])}
		}
	}
}

// EphemeralDisk is an ephemeral disk object.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L364-L369
#EphemeralDisk: {
	Sticky:  bool | *false
	Migrate: bool | *false
	// SizeMB is the size of the ephemeral disk in MiB.
	SizeMB: uint | *300
}

// MigrateStrategy describes how allocations for a task group should be
// migrated between nodes (eg when draining).
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L391-L398
#MigrateStrategy: {
	MaxParallel:     uint | *1
	HealthCheck:     *"checks" | "task_states"
	MinHealthyTime:  #Duration | *(10 * time.Second)
	HealthyDeadline: #Duration | *(5 * time.Minute)
}

// VolumeRequest is a representation of a storage volume that a TaskGroup wishes to use.
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L452-L464
#VolumeRequest: {
	Name:     string
	Type:     "host" | "csi"
	Source:   string
	ReadOnly: bool | *false
	Sticky:   bool | *false
	PerAlloc: bool | *false

	if Sticky {
		PerAlloc: false
	}

	if Type == "csi" {
		AccessMode: "single-node-reader-only" |
			"single-node-writer" |
			"multi-node-reader-only" |
			"multi-node-single-writer" |
				"multi-node-multi-writer"
		AttachmentMode: "file-system" | "block-device"
		MountOptions:   #CSIMountOptions | *null
	}

	if Type == "host" {
		AccessMode?: "single-node-writer" |
			"single-node-reader-only" |
			"single-node-single-writer" |
					"single-node-multi-writer"
		AttachmentMode?: *"file-system" | "block-device"
	}
}

// VolumeMount represents the relationship between a destination path in a task
// and the task group volume that should be mounted there.
// https://developer.hashicorp.com/nomad/docs/job-specification/volume_mount
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L472-L480
#VolumeMount: {
	Volume:          string
	Destination:     string
	ReadOnly:        bool | *false
	PropagationMode: *"private" | "host-to-task" | "bidirectional"
	SELinuxLabel:    string | *""
}

// LogConfig provides configuration for log rotation.
// https://developer.hashicorp.com/nomad/docs/job-specification/logs
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L716-L726
#LogConfig: {
	MaxFiles:      uint | *10
	MaxFileSizeMB: uint | *10
	Disabled:      bool | *false
}

// https://developer.hashicorp.com/nomad/docs/job-specification/dispatch_payload
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L748-L751
#DispatchPayloadConfig: {
	File: string
}

// https://developer.hashicorp.com/nomad/docs/job-specification/lifecycle
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L759-L762
#TaskLifecycle: {
	Hook:    "prestart" | "poststart" | "poststop"
	Sidecar: bool | *false
}

// Task is a single process in a task group.
// https://developer.hashicorp.com/nomad/docs/job-specification/task
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L769-L808
#Task: {
	taskName=Name: string
	Driver:        string
	User?:         string
	Lifecycle:     #TaskLifecycle | *null
	Config: {[string]: _}
	Constraints: [...#Constraint]
	Affinities: [...#Affinity]
	Env: {[string]: string}
	Services: [...#Service & {TaskName: taskName}]
	Resources:     #Resources
	RestartPolicy: #RestartPolicy | *null
	Meta: {[string]: string}
	KillTimeout: #Duration | *(5 * time.Second)
	LogConfig:   #LogConfig
	Artifacts: [...#TaskArtifact]
	Vault:  #Vault | *null
	Consul: #Consul | *null
	Templates: [...#Template]
	DispatchPayload: #DispatchPayloadConfig | *null
	VolumeMounts: [...#VolumeMount]
	// TODO(someday): CSIPluginConfig: #TaskCSIPluginConfig | *null
	Leader:        bool | *false
	ShutdownDelay: #Duration | *0
	KillSignal?:   string
	Kind?:         string
	ScalingPolicies: [...#ScalingPolicy]
	Identity: #WorkloadIdentity | *null
	Identities: [...#WorkloadIdentity]
	Actions: [...#Action]
	Schedule: #TaskSchedule | *null

	if Driver == "docker" {
		Config: #DockerTaskConfig
	}
}

_#TaskWithDefaults: {
	X=in: {
		JobName:   string
		GroupName: string
	}

	out: #Task & {
		Services: [...(_#ServiceWithDefaults & {in: X}).out]
	}
}

// https://developer.hashicorp.com/nomad/docs/job-specification/artifact
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L861-L870
#TaskArtifact: {
	// GetterSource is the URL of the artifact to download.
	GetterSource: string
	GetterOptions: [string]: string
	GetterHeaders: [string]: string
	GetterMode:     *"any" | "file" | "dir"
	GetterInsecure: bool | *false
	RelativeDest?:  string
	Chown:          bool | *false
}

// https://developer.hashicorp.com/nomad/docs/job-specification/change_script
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L922-L927
#ChangeScript: {
	Command: string
	Args: [...string]
	Timeout:     #Duration | *(5 * time.Second)
	FailOnError: bool | *false
}

// https://developer.hashicorp.com/nomad/docs/job-specification/template
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L944-L962
#Template: {
	{SourcePath: string & !=""} |
	{EmbeddedTmpl: string & !=""}
	DestPath:   string
	ChangeMode: "noop" | *"restart" | "signal" | "script"
	Once:       bool | *false
	Splay:      #Duration | *(5 * time.Second)
	Perms:      =~"^[0-7]{1,4}$" | *"0644"
	Uid:        int | *null
	Gid:        int | *null
	LeftDelim:  string | *"{{"
	RightDelim: string | *"}}"
	Envvars:    bool | *false
	// TODO(someday): Wait
	ErrMissingKey: bool | *false

	if ChangeMode == "signal" {
		ChangeSignal: string
	}
	if ChangeMode == "script" {
		ChangeScript: #ChangeScript
	}
}

// https://developer.hashicorp.com/nomad/docs/job-specification/vault
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L1017-L1027
#Vault: {
	Policies: [...string]
	Role?:                string
	Namespace?:           string
	Cluster:              string | *"default"
	Env:                  bool | *true
	DisableFile:          bool | *false
	ChangeMode:           "noop" | *"restart" | "signal"
	AllowTokenExpiration: bool | *false

	if ChangeMode == "signal" {
		ChangeSignal: string
	}
}

// WorkloadIdentity is the jobspec block which determines if and how a workload
// identity is exposed to tasks.
// https://developer.hashicorp.com/nomad/docs/job-specification/identity
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L1236-L1248
#WorkloadIdentity: {
	Name: string | *"default"
	Audience: [...string]
	ChangeMode: *"noop" | "restart" | "signal"
	Env:        bool | *false
	File:       bool | *false

	if ChangeMode == "signal" {
		ChangeSignal: string
	}
	if File {
		Filepath: string
	}
	if Name != "default" {
		TTL: #Duration
	}
}

// https://developer.hashicorp.com/nomad/docs/job-specification/action
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/tasks.go#L1250-L1254
#Action: {
	Name:    string & =~"^[-a-zA-Z0-9]{1,128}$"
	Command: string
	Args: [...string]
}

// https://developer.hashicorp.com/nomad/docs/job-specification/schedule
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/task_sched.go#L6-L8
#TaskSchedule: {
	Cron: #TaskScheduleCron
}

// https://developer.hashicorp.com/nomad/docs/job-specification/schedule
// https://github.com/hashicorp/nomad/blob/v1.10.3/api/task_sched.go#L10-L14
#TaskScheduleCron: {
	Start:     string
	End:       string
	Timezone?: string
}
