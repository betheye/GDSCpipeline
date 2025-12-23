#!/bin/bash
#SBATCH --job-name=gdsc_training
#SBATCH --output=logs/training_%j.out
#SBATCH --error=logs/training_%j.err
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --partition=normal

# ============================================================================
# HPC Training Script
# ============================================================================
# Submit with: sbatch submit_training.sh
# ============================================================================

echo "============================================================"
echo "Drug Sensitivity Model Training - HPC"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $SLURMD_NODENAME"
echo "CPUs: $SLURM_CPUS_PER_TASK"
echo "Start time: $(date)"
echo "============================================================"

# Create logs directory
mkdir -p logs

# Load R module (adjust for your HPC)
module load R/4.3.1 || module load R || echo "R module not found, using system R"

# Set working directory
cd /path/to/scripts_organized  # <-- UPDATE THIS PATH

# Set parallel threads
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

echo ""
echo "=== Step 1: Data Preprocessing ==="
Rscript 01_data_preprocessing.r

echo ""
echo "=== Step 2: Train/Test Split ==="
Rscript 02_train_test_split.r

echo ""
echo "=== Step 3: Feature Encoding ==="
Rscript 03_feature_encoding.r

echo ""
echo "=== Step 4: Model Training ==="
Rscript 04_model_training.r

echo ""
echo "=== Step 5: Performance Analysis ==="
Rscript 05_performance_analysis.r

echo ""
echo "============================================================"
echo "Training complete!"
echo "End time: $(date)"
echo "============================================================"
