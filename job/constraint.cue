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

// https://github.com/hashicorp/nomad/blob/v1.10.3/api/constraint.go
#Constraint: {
	// LTarget is the name or reference of the attribute to examine for the constraint.
	LTarget: string
	// RTarget is the value to compare the attribute against using the specified operation.
	RTarget: string
	Operand: "=" |
		"!=" |
		">" |
		">=" |
		"<" |
		"<=" |
		"distinct_hosts" |
		"distinct_property" |
		"regexp" |
		"set_contains" |
		"set_contains_any" |
		"version" |
		"semver" |
		"is_set" |
		"is_not_set"
}
