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

import (
	"net"
	"time"
)

// https://developer.hashicorp.com/nomad/docs/v1.10.x/job-declare/task-driver/docker
// https://github.com/hashicorp/nomad/blob/v1.10.3/drivers/docker/config.go#L359-L437
#DockerTaskConfig: {
	image:                  string
	advertise_ipv6_address: bool | *false
	args: [...string]
	auth?: {
		username?:       string
		password?:       string
		email?:          string
		server_address?: string
	}
	auth_soft_fail: bool | *false
	cap_add: [...string]
	cap_drop: [...string]
	cgroupns?:                 "host" | "private"
	command?:                  string
	cpuset_cpus?:              string
	cpu_hard_limit:            bool | *false
	cpu_cfs_period:            (uint & <=1_000_000) | *100_000
	container_exists_attempts: uint | *5
	devices: [...{
		host_path:          string
		container_path:     host_path
		cgroup_permissions: =~"^r?w?m?$" | *"rwm"
	}]
	dns_search_domains?: [...string]
	dns_options?: [...string]
	entrypoint?: [...string]
	extra_hosts?: [...string]
	force_pull: bool | *false
	group_add: [...string]
	healthchecks: {
		disable: bool | *false
	}
	hostname?:     string
	init:          bool | *false
	interactive:   bool | *false
	ipc_mode:      string | *"none"
	ipv4_address?: string & net.IPv4
	ipv6_address?: string & net.IPv4
	isolation?:    *"hyperv" | "process"
	labels: [{[string]: string}]
	load?: string
	logging?: {
		type?:   string
		driver?: string
		config: [{[string]: string}]
	}
	mac_address?:       string
	memory_hard_limit?: int
	mount: [...#DockerMountBodySpec]
	network_aliases: [...string]
	network_mode?: "default" | "bridge" | "host" | "none" | =~"^container:"
	oom_score_adj: uint | *0
	runtime?:      string
	pids_limit?:   uint
	pid_mode?:     "host"
	ports: [...string]
	privileged:         bool | *false
	image_pull_timeout: (string & time.Duration) | *"5m"
	readonly_rootfs:    bool | *false
	security_opt: [...string]
	shm_size?: uint
	storage_opt: {[string]: string}
	sysctl: [{[string]: string}]
	tty: bool | *false
	ulimit: [{[string]: string}]
	uts_mode?:    "host"
	userns_mode?: "host"
	volumes: [...(=~":")]
	volume_driver?: string
	work_dir?:      string
}

// https://web.archive.org/web/20250813223901/https://docs.docker.com/reference/cli/docker/service/create/#mount
// https://github.com/hashicorp/nomad/blob/v1.10.3/drivers/docker/config.go#L326-L350
#DockerMountBodySpec: {
	type:     "volume"
	target:   string
	source?:  string
	readonly: bool | *false
	volume_options?: {
		no_copy: bool | *false
		labels: [{[string]: string}]
		driver_config?: [{
			name: string
			options?: [{[string]: string}]
		}]
	}
} | {
	type:     "bind"
	target:   string
	source:   string
	readonly: bool | *false
	bind_options: [{
		propagation: "shared" | "slave" | "private" | "rshared" | "rslave" | *"rprivate"
	}]
} | {
	type:     "tmpfs"
	target:   string
	readonly: bool | *false
	tmpfs_options: [{
		size?: uint
		mode:  uint | *0o1777
	}]
}
