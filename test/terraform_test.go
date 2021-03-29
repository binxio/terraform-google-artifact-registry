package test

import (
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/gcp"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// Give this Bucket an environment to operate as a part of, for the purposes of resource tagging
// Give it a random string so we're sure it's created this test run
var expectedEnvironment string
var testPreq *testing.T
var terraformOptions *terraform.Options
var tmpSaReaderEmail string
var tmpSaOwnerEmail string
var blacklistRegions []string
var projectId string
var region string

func TestMain(m *testing.M) {
	expectedEnvironment = fmt.Sprintf("terratest %s", strings.ToLower(random.UniqueId()))
	blacklistRegions = []string{"asia-east2"}

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt)
	go func(){
		<-c
		TestCleanup(testPreq)
		Clean()
		os.Exit(1)
	}()

	result := 0
	defer func() {
		TestCleanup(testPreq)
		Clean()
		os.Exit(result)
	}()
	result = m.Run()
}

// -------------------------------------------------------------------------------------------------------- //
// Utility functions
// -------------------------------------------------------------------------------------------------------- //
func setTerraformOptions(dir string) {
	terraformOptions = &terraform.Options {
		TerraformDir: dir,
		// Pass the expectedEnvironment for tagging
		Vars: map[string]interface{}{
			"environment": expectedEnvironment,
			"location": region,
			"sa_reader_email": tmpSaReaderEmail,
			"sa_owner_email": tmpSaOwnerEmail,
		},
		EnvVars: map[string]string{
			"GOOGLE_CLOUD_PROJECT": projectId,
		},
	}
}

// A build step that removes temporary build and test files
func Clean() error {
	fmt.Println("Cleaning...")

	return filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && info.Name() == "vendor" {
			return filepath.SkipDir
		}
		if info.IsDir() && info.Name() == ".terraform" {
			os.RemoveAll(path)
			fmt.Printf("Removed \"%v\"\n", path)
			return filepath.SkipDir
		}
		if !info.IsDir() && (info.Name() == "terraform.tfstate" ||
		info.Name() == "terraform.tfplan" ||
		info.Name() == "terraform.tfstate.backup") {
			os.Remove(path)
			fmt.Printf("Removed \"%v\"\n", path)
		}
		return nil
	})
}

func Test_Prereq(t *testing.T) {
	projectId = gcp.GetGoogleProjectIDFromEnvVar(t)
	// Pick a random GCP region to test in. This helps ensure your code works in all regions.
	region = gcp.GetRandomRegion(t, projectId, nil, blacklistRegions)

	setTerraformOptions(".")
	testPreq = t

	terraform.InitAndApply(t, terraformOptions)

	tmpSaReaderEmail = terraform.OutputRequired(t, terraformOptions, "sa_reader_email")
	tmpSaOwnerEmail = terraform.OutputRequired(t, terraformOptions, "sa_owner_email")
}

// -------------------------------------------------------------------------------------------------------- //
// Unit Tests
// -------------------------------------------------------------------------------------------------------- //
func TestUT_Assertions(t *testing.T) {
	expectedAssertUnknownVar := "Unknown repository variable assigned"
	expectedAssertNameTooLong := "'s generated name is too long:"
	expectedAssertNameInvalidChars := "does not match regex"

	setTerraformOptions("assertions")

	out, err := terraform.InitAndPlanE(t, terraformOptions)

	require.Error(t, err)
	assert.Contains(t, out, expectedAssertUnknownVar)
	assert.Contains(t, out, expectedAssertNameTooLong)
	assert.Contains(t, out, expectedAssertNameInvalidChars)
}

func TestUT_Defaults(t *testing.T) {
	setTerraformOptions("defaults")
	terraform.InitAndPlan(t, terraformOptions)
}

func TestUT_Overrides(t *testing.T) {
	setTerraformOptions("overrides")
	terraform.InitAndPlan(t, terraformOptions)
}

// -------------------------------------------------------------------------------------------------------- //
// Integration Tests
// -------------------------------------------------------------------------------------------------------- //

func TestIT_Defaults(t *testing.T) {
	setTerraformOptions("defaults")

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)

	// Ugly typecasting because Go....
	repositoryMap := outputs["map"].(map[string]interface{})
	repository := repositoryMap["app"].(map[string]interface{})
	repositoryId := repository["id"].(string)

	// Make sure our repository is created
	fmt.Printf("Checking repository %s...\n", repositoryId)
}

func TestIT_Overrides(t *testing.T) {
	setTerraformOptions("overrides")

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	outputs := terraform.OutputAll(t, terraformOptions)

	// Ugly typecasting because Go....
	repositoryMap := outputs["map"].(map[string]interface{})
	repository := repositoryMap["app"].(map[string]interface{})
	repositoryId := repository["id"].(string)

	// Make sure our repository is created
	fmt.Printf("Checking repository %s...\n", repositoryId)
}

func TestCleanup(t *testing.T) {
	fmt.Println("Cleaning possible lingering resources..")
	terraform.Destroy(t, terraformOptions)

	// Also clean up prereq. resources
	fmt.Println("Cleaning our prereq resources...")
	setTerraformOptions(".")
	terraform.Destroy(t, terraformOptions)
}
