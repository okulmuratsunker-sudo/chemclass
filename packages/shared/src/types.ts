import type { Tables } from "./database.types"

export type Role = "teacher" | "student"

export type Profile = Tables<"profiles">
export type ClassRow = Tables<"classes">
export type ClassStudent = Tables<"class_students">
export type Group = Tables<"groups">
export type GroupMember = Tables<"group_members">
export type BehaviorPoint = Tables<"behavior_points">
export type Grade = Tables<"grades">
export type Message = Tables<"messages">
export type Homework = Tables<"homework">
export type Announcement = Tables<"announcements">
export type ScheduleEntry = Tables<"schedule_entries">
export type BoardSession = Tables<"board_sessions">
export type BoardState = Tables<"board_state">
export type PushToken = Tables<"push_tokens">
