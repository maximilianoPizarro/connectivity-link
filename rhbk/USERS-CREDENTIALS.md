# Developer Hub User Credentials

## Keycloak Admin Console (RHBK default admin)

The **Keycloak Admin Console** (`https://rhbk.apps.<cluster-domain>/admin`) uses a separate initial admin user:

| Field    | Value |
|----------|--------|
| Username | `admin` |
| Password | `d9faa9d643ed4704b413f8d0b0a7e7d3` |

This account is used to manage Keycloak (realms, clients, users). Change this password in production.

---

## Users Added (Backstage realm)

10 users have been added to the Keycloak `backstage` realm with common access (username/password).

### Access Credentials

All users have the same default password:

**Default Password:** `Welcome123!`

⚠️ **IMPORTANT:** It is recommended to change these passwords after the first login.

### User List

| Username | Email | Full Name | Group Assignment |
|----------|-------|-----------|------------------|
| user1-dev | user1@developer-hub.local | User One | developers |
| user2-dev | user2@developer-hub.local | User Two | developers |
| user3-devteam1 | user3@developer-hub.local | User Three | devteam1 |
| user4-devteam1 | user4@developer-hub.local | User Four | devteam1 |
| user5-infra | user5@developer-hub.local | User Five | infrastructure |
| user6-infra | user6@developer-hub.local | User Six | infrastructure |
| user7-platform | user7@developer-hub.local | User Seven | platformengineers |
| user8-platform | user8@developer-hub.local | User Eight | platformengineers |
| user9-rhdh | user9@developer-hub.local | User Nine | rhdh |
| user10-rhdh | user10@developer-hub.local | User Ten | rhdh |

## How to Access Developer Hub

1. **Open Developer Hub:**
   - Navigate to the Developer Hub URL (e.g., `https://developer-hub.apps.<cluster-domain>`)

2. **Sign In:**
   - Click on "Sign In"
   - You will be redirected to Keycloak

3. **Authentication:**
   - Use your **username** (e.g., `user1-dev`) or **email** (e.g., `user1@developer-hub.local`)
   - Enter the password: `Welcome123!`
   - Click "Sign In"
   
   **Note:** Usernames include the group suffix (e.g., `-dev`, `-devteam1`, `-infra`, `-platform`, `-rhdh`) to indicate their group assignment.

4. **First Time:**
   - If this is your first login, Keycloak may ask you to update your profile
   - Complete the required information if necessary

## Linking with Developer Hub

Users are configured with:
- **Realm:** `backstage`
- **Roles:** `default-roles-backstage` (basic realm roles)
- **Groups:** Randomly distributed across existing groups (see table above)
- **Status:** Enabled and email verified
- **Authentication:** Username/Password enabled

### Group Distribution

The 10 users have been randomly distributed across the existing Keycloak groups. Usernames include the group suffix for easy identification:
- **developers** (2 users): `user1-dev`, `user2-dev`
- **devteam1** (2 users): `user3-devteam1`, `user4-devteam1`
- **infrastructure** (2 users): `user5-infra`, `user6-infra`
- **platformengineers** (2 users): `user7-platform`, `user8-platform`
- **rhdh** (2 users): `user9-rhdh`, `user10-rhdh`

Groups are linked in Keycloak and will be available in Developer Hub for RBAC and filtering purposes.

### Backstage Configuration

Backstage is configured to use Keycloak as the OIDC provider:
- **Realm:** `backstage`
- **Client ID:** `backstage`
- **Provider:** OIDC

Users will be automatically linked when they sign in for the first time using the `preferredUsernameMatchingUserEntityName` resolver.

## Assigning Additional Permissions

If you need to grant additional permissions to these users in Backstage, you can:

1. **Add to groups in Keycloak:**
   - Available groups are: `developers`, `devteam1`, `infrastructure`, `platformengineers`, `rhdh`
   - Edit the user in Keycloak and add them to the desired group

2. **Assign roles in Backstage RBAC:**
   - Edit `developer-hub/rhdh-rbac-policy.yaml`
   - Add specific permissions for each user or group

3. **Example of permission assignment:**
   ```yaml
   # In rhdh-rbac-policy.yaml
   p, user:default/user1, catalog-entity, read, allow
   p, user:default/user1, catalog-entity, create, allow
   ```

## Changing Passwords

Users can change their passwords:

1. **From Keycloak:**
   - Sign in to Keycloak Admin Console
   - Go to Users → Select the user → Credentials → Set Password

2. **From Developer Hub (if enabled):**
   - Sign in to Developer Hub
   - Go to your profile → Change password
   - You will be redirected to Keycloak to change the password

## Troubleshooting

### User cannot sign in
- Verify that the user is enabled (`enabled: true`)
- Verify that the email is verified (`emailVerified: true`)
- Verify that the password is correct

### User does not appear in Developer Hub
- Verify that the user has signed in at least once
- Verify that the user resolver in Backstage is configured correctly
- Check Backstage logs for authentication errors

### Insufficient permissions
- Verify the roles assigned in Keycloak
- Verify RBAC policies in `developer-hub/rhdh-rbac-policy.yaml`
- Ensure the user has the necessary permissions

## Security Notes

⚠️ **IMPORTANT:**
- Change default passwords after first use
- Do not share these credentials in public repositories
- Consider using stronger passwords in production
- Enable MFA (Multi-Factor Authentication) if necessary

