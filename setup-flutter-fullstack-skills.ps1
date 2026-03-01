$skillsDir = "c:\Users\Admin\Desktop\Uni Work\Flutter1\.agent\skills"

$categories = @{
    "architecture-system-design" = @("architecture", "senior-architect", "api-design-principles", "api-patterns", "brainstorming")
    "frontend-ui-ux" = @("ui-ux-designer", "ui-ux-pro-max", "frontend-design", "frontend-dev-guidelines", "frontend-mobile-development-component-scaffold")
    "mobile-multi-platform" = @("flutter-expert", "mobile-design", "mobile-developer", "multi-platform-apps-multi-platform")
    "backend-api-engineering" = @("backend-architect", "backend-dev-guidelines", "nodejs-backend-patterns", "fastapi-pro", "golang-pro")
    "database-cloud-services" = @("database-design", "database-optimizer", "postgres-best-practices", "firebase")
    "security-identity" = @("api-security-best-practices", "auth-implementation-patterns", "mobile-security-coder")
    "testing-qa" = @("debugging-strategies", "test-driven-development", "testing-patterns", "webapp-testing")
    "engineering-practices" = @("clean-code", "code-reviewer", "doc-coauthoring")
}

foreach ($category in $categories.GetEnumerator()) {
    $groupName = $category.Key
    $skillList = $category.Value
    
    $groupPath = Join-Path $skillsDir $groupName
    
    if (-Not (Test-Path $groupPath)) {
        New-Item -ItemType Directory -Path $groupPath | Out-Null
    }

    foreach ($skill in $skillList) {
        $skillPath = Join-Path $skillsDir $skill
        if (Test-Path $skillPath) {
            Move-Item -Path $skillPath -Destination $groupPath
        }
    }
}
Write-Host "Đã phân loại xong!"
