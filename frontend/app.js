import { contractAddress } from './constants/contractAddress.js';

const connectWalletBtn = document.getElementById('connectWalletBtn');
const coffeeForm = document.getElementById('coffeeForm');
const buyCoffeeBtn = document.getElementById('buyCoffeeBtn');
const memosContainer = document.getElementById('memosContainer');
const adminSection = document.getElementById('adminSection');
const withdrawBtn = document.getElementById('withdrawBtn');

let provider;
let signer;
let contract;
let contractABI;
let userAddress;
let isOwner = false;

// Initialize app
async function init() {
    try {
        // Fetch ABI
        const response = await fetch('./constants/BuyMeACoffee.json');
        if (!response.ok) {
            console.warn("ABI not found. Have you deployed the contract?");
            return;
        }
        const artifact = await response.json();
        contractABI = artifact.abi;
        
        setupEventListeners();
        checkIfWalletIsConnected();
    } catch (error) {
        console.error("Failed to initialize:", error);
    }
}

function setupEventListeners() {
    connectWalletBtn.addEventListener('click', connectWallet);
    coffeeForm.addEventListener('submit', buyCoffee);
    withdrawBtn.addEventListener('click', withdrawTips);
}

async function checkIfWalletIsConnected() {
    if (window.ethereum) {
        provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.listAccounts();
        if (accounts.length > 0) {
            signer = await provider.getSigner();
            userAddress = await signer.getAddress();
            updateWalletUI(userAddress);
            await setupContract();
        }
    } else {
        console.log("No metamask detected!");
    }
}

async function connectWallet() {
    if (!window.ethereum) {
        alert("Please install MetaMask!");
        return;
    }
    try {
        provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.send("eth_requestAccounts", []);
        signer = await provider.getSigner();
        userAddress = await signer.getAddress();
        updateWalletUI(userAddress);
        await setupContract();
    } catch (error) {
        console.error("Wallet connection failed:", error);
    }
}

function updateWalletUI(address) {
    connectWalletBtn.innerText = address.slice(0, 6) + "..." + address.slice(-4);
    connectWalletBtn.classList.remove('bg-indigo-400');
    connectWalletBtn.classList.add('bg-green-400');
}

async function setupContract() {
    if (!contractAddress || contractAddress === "") {
        console.warn("Contract address not set in constants/contractAddress.js");
        return;
    }

    contract = new ethers.Contract(contractAddress, contractABI, signer);
    
    // Check if current user is owner
    try {
        const ownerAddress = await contract.owner();
        if (ownerAddress.toLowerCase() === userAddress.toLowerCase()) {
            isOwner = true;
            adminSection.classList.remove('hidden');
        } else {
            isOwner = false;
            adminSection.classList.add('hidden');
        }
    } catch (error) {
        console.error("Failed to fetch owner:", error);
    }

    // Load Memos
    await loadMemos();
    
    // Listen for events
    contract.on("NewMemo", (from, timestamp, name, message) => {
        console.log("New memo received!", name, message);
        loadMemos(); // Reload list
    });
}

async function buyCoffee(e) {
    e.preventDefault();
    if (!contract) {
        alert("Connect your wallet first or ensure contract is deployed!");
        return;
    }
    
    const nameInput = document.getElementById('nameInput').value;
    const messageInput = document.getElementById('messageInput').value;

    try {
        const amount = ethers.parseEther("0.001");
        const tx = await contract.buyCoffee(nameInput, messageInput, { value: amount });
        
        buyCoffeeBtn.innerText = "Processing...";
        buyCoffeeBtn.disabled = true;

        await tx.wait();
        
        console.log("Coffee bought successfully!", tx.hash);
        coffeeForm.reset();
    } catch (error) {
        console.error("Error buying coffee:", error);
        alert("Transaction failed! Check console.");
    } finally {
        buyCoffeeBtn.innerText = "💸 Buy 1 Coffee (0.001 ETH)";
        buyCoffeeBtn.disabled = false;
    }
}

async function withdrawTips() {
    if (!isOwner || !contract) return;

    try {
        withdrawBtn.innerText = "Withdrawing...";
        withdrawBtn.disabled = true;

        const tx = await contract.withdrawTips();
        await tx.wait();

        alert("Tips withdrawn successfully!");
    } catch (error) {
        console.error("Withdrawal error:", error);
        alert("Withdrawal failed!");
    } finally {
        withdrawBtn.innerText = "💰 Withdraw Tips";
        withdrawBtn.disabled = false;
    }
}

async function loadMemos() {
    if (!contract) return;
    
    try {
        const memos = await contract.getMemos();
        
        if (memos.length === 0) return;

        memosContainer.innerHTML = '';
        
        const sortedMemos = [...memos].sort((a, b) => Number(b.timestamp) - Number(a.timestamp));
        
        sortedMemos.forEach(memo => {
            const date = new Date(Number(memo.timestamp) * 1000).toLocaleString();
            
            const memoEl = document.createElement('div');
            memoEl.className = 'neo-memo-card flex flex-col gap-2';
            memoEl.innerHTML = `
                <div class="flex justify-between items-start border-b-2 border-black pb-2">
                    <span class="font-black text-lg uppercase">${memo.name || "Anonymous"}</span>
                    <span class="text-xs font-bold bg-blue-200 px-2 py-1 border-2 border-black">${date}</span>
                </div>
                <p class="text-gray-800 font-medium italic text-lg">"${memo.message}"</p>
                <div class="text-xs text-gray-500 font-mono mt-2">From: ${memo.from}</div>
            `;
            memosContainer.appendChild(memoEl);
        });
        
    } catch (error) {
        console.error("Failed to load memos:", error);
    }
}

init();
