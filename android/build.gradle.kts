// Top-level build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ⚠️ REMOVE custom build directory override
// val newBuildDir = rootProject.layout.buildDirectory.dir("../../build")
// rootProject.layout.buildDirectory.set(newBuildDir)

// subprojects {
//     layout.buildDirectory.set(newBuildDir.map { it.dir(name) })
//     evaluationDependsOn(":app")
// }

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
