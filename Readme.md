Installation and Execution
Follow these steps to run and interact with the TruthChain System.

Step 1: Run the Frontend
    Open a terminal and navigate to the project folder.
    Enter the frontend directory:
        bash
        ->cd misinformation-frontend

    Install dependencies and start the React application:
        bash
        ->npm install
        ->npm start
    The app will launch in your browser at http://localhost:3000.
    Ensure That you have your Metamesk Working or Logged in.


Step 2: Deploy Smart Contracts
    Go to Remix IDE (https://remix.ethereum.org/).
    Create two files under the contracts/ directory:
        ContentRegistry.sol
        ReputationSystem.sol
    Compile both contracts using Solidity version 0.8.20.
    In the Deploy & Run Transactions tab, select Injected Provider - MetaMask.
    Connect MetaMask to the Sepolia Testnet and ensure it has test ETH (e.g., from https://sepoliafaucet.com/).
    Deploy ReputationSystem.sol and copy its address (e.g., 0xABC...).
    Deploy ContentRegistry.sol, passing the ReputationSystem address (0xABC...) as the constructor parameter. Copy its address (e.g., 0xDEF...).
    In ReputationSystem.sol, call the setContentRegistry function with the ContentRegistry address (0xDEF...) to link the contracts.


Step 3: Configure the Website
    Access the frontend at http://localhost:3000.
    A prompt will request the contract addresses.
    Enter the following:
        ReputationSystem address (e.g., 0xABC...)
        ContentRegistry address (e.g., 0xDEF...)
    Save the addresses to continue.


Step 4: Upload Content
    In MetaMask, select an account with sufficient reputation (e.g., Account 1, reputation 50).
    On the website, go to the Content Submission section.
    Upload a file (e.g., news.txt) to IPFS using Pinata.
    Click the Register button to record the IPFS hash on-chain.
    The content will appear in the My Content section, marked as Unverified (orange border).

Step 5: Verify Content
    Switch MetaMask to another account with sufficient reputation (e.g., Account 2, reputation ≥ 35).
    Navigate to the Needs Verification section and select the content (e.g., news.txt).
    Assign a score (0–100) using the slider and submit the verification.
    Repeat with additional accounts (e.g., Accounts 3 and 4) until the content receives 3 verifications.
    The content will be finalized as:
    Correct: Score ≥ 70 (blue card).
    Incorrect: Score < 70 (red card).


Additional Notes
    MetaMask: Must remain connected to the Sepolia Testnet during all interactions.
    Reputation: Accounts used for uploading or verifying content must meet the reputation thresholds defined in the smart contracts.
    Contract Linking: Ensure the ReputationSystem and ContentRegistry contracts are correctly linked via their addresses.