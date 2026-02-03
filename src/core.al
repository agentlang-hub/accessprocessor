module accessprocessor.core

record incidentInformation {
    sys_id String @optional,
    status String @optional,
    data Any @optional,
    category String @optional,
    ai_status String @optional,
    ai_processor String @optional,
    requires_human Boolean @optional,
    ai_reason String @optional,
    resolution String @optional
}

event handlePermission {
    userEmail Email,
    resourceName String,
    permissionLevel @enum("read", "write", "admin", "custom") @optional
}

workflow handlePermission {
    console.log("++PERMISSION++ " + handlePermission.userEmail + " for " + handlePermission.resourceName)
}

event handleRoleAssignment {
    userEmail Email,
    roleName String,
    action @enum("add", "remove", "modify") @optional
}

workflow handleRoleAssignment {
    console.log("++ROLE_ASSIGNMENT++ " + handleRoleAssignment.userEmail + " for " + handleRoleAssignment.roleName)
}

event handleGroupMembership {
    userEmail Email,
    groupName String,
    action @enum("add", "remove") @optional
}

workflow handleGroupMembership {
    console.log("++GROUP_MEMBERSHIP++ " + handleGroupMembership.userEmail + " for " + handleGroupMembership.groupName)
}

agent permissionHandler {
    instruction "Extract details and call handlePermission.",
    tools "accessprocessor.core/handlePermission"
}

agent roleAssignmentHandler {
    instruction "Extract details and call handleRoleAssignment.",
    tools "accessprocessor.core/handleRoleAssignment"
}

agent groupMembershipHandler {
    instruction "Extract details and call handleGroupMembership.",
    tools "accessprocessor.core/handleGroupMembership"
}

agent accessTriager {
    instruction "Classify the access request into PERMISSION, ROLE_ASSIGNMENT, GROUP_MEMBERSHIP, or UNKNOWN.
Only return one of the strings [PERMISSION, ROLE_ASSIGNMENT, GROUP_MEMBERSHIP, UNKNOWN] and nothing else."
}

flow accessOrchestrator {
    accessTriager --> "PERMISSION" permissionHandler
    accessTriager --> "ROLE_ASSIGNMENT" roleAssignmentHandler
    accessTriager --> "GROUP_MEMBERSHIP" groupMembershipHandler
    accessTriager --> "UNKNOWN" {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "failed-to-process", requires_human true}}
    permissionHandler --> {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "processed"}}
    roleAssignmentHandler --> {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "processed"}}
    groupMembershipHandler --> {servicenow/incident {sys_id? incidentInformation.sys_id, ai_status "processed"}}
}

@public agent accessOrchestrator {
    role "You are an access management and identity governance specialist."
}

workflow @after update:servicenow/incident {
    if (servicenow/incident.category == "ACCESS" or servicenow/incident.ai_processor == "access") {
        {incidentInformation {
            sys_id servicenow/incident.sys_id,
            status servicenow/incident.state,
            data servicenow/incident.data,
            category servicenow/incident.category,
            ai_status servicenow/incident.ai_status,
            ai_processor servicenow/incident.ai_processor,
            requires_human servicenow/incident.requires_human,
            ai_reason servicenow/incident.ai_reason,
            resolution servicenow/incident.resolution
        }}

        {accessOrchestrator {message servicenow/incident}}
    }
}
