#!/usr/bin/env python3
"""
Generate Project Hydra PowerPoint Presentation
Uses python-pptx to create a comprehensive presentation
"""

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor

def create_presentation():
    prs = Presentation()
    prs.slide_width = Inches(10)
    prs.slide_height = Inches(7.5)
    
    # Slide 1: Title Slide
    slide1 = prs.slides.add_slide(prs.slide_layouts[0])
    title = slide1.shapes.title
    subtitle = slide1.placeholders[1]
    title.text = "Project Hydra"
    subtitle.text = "Cross-Device Edge Supercomputer\niPhone 17 Pro + Samsung S25"
    
    # Slide 2: Summary
    slide2 = prs.slides.add_slide(prs.slide_layouts[1])
    title2 = slide2.shapes.title
    title2.text = "Executive Summary"
    content2 = slide2.placeholders[1]
    tf2 = content2.text_frame
    tf2.text = "Project Hydra transforms a Samsung S25 into a distributed edge compute node for iPhone 17 Pro"
    p2 = tf2.add_paragraph()
    p2.text = "• Real-time RAW image processing and ML inference"
    p2.level = 1
    p2 = tf2.add_paragraph()
    p2.text = "• QUIC-based high-throughput communication (500+ MB/s)"
    p2.level = 1
    p2 = tf2.add_paragraph()
    p2.text = "• Persistent job recovery and battery-aware scheduling"
    p2.level = 1
    p2 = tf2.add_paragraph()
    p2.text = "• Zero-copy data transfer with sub-100ms latency"
    p2.level = 1
    
    # Slide 3: Problems & Vision
    slide3 = prs.slides.add_slide(prs.slide_layouts[1])
    title3 = slide3.shapes.title
    title3.text = "Problems & Vision"
    content3 = slide3.placeholders[1]
    tf3 = content3.text_frame
    tf3.text = "Problem Statement"
    p3 = tf3.add_paragraph()
    p3.text = "• iPhone 17 Pro: Excellent camera, limited RAM for large RAW processing"
    p3.level = 1
    p3 = tf3.add_paragraph()
    p3.text = "• Samsung S25: Powerful GPU/NPU, abundant RAM, underutilized compute"
    p3.level = 1
    p3 = tf3.add_paragraph()
    p3.text = "Solution"
    p3.level = 0
    p3 = tf3.add_paragraph()
    p3.text = "• Distributed system: iPhone orchestrates, Samsung computes"
    p3.level = 1
    p3 = tf3.add_paragraph()
    p3.text = "• Leverage strengths of both devices"
    p3.level = 1
    p3 = tf3.add_paragraph()
    p3.text = "• Production-ready with full crash recovery"
    p3.level = 1
    
    # Slide 4: Architecture Overview
    slide4 = prs.slides.add_slide(prs.slide_layouts[1])
    title4 = slide4.shapes.title
    title4.text = "Architecture Overview"
    content4 = slide4.placeholders[1]
    tf4 = content4.text_frame
    tf4.text = "iPhone 17 Pro (iOS)"
    p4 = tf4.add_paragraph()
    p4.text = "• RAW Capture Pipeline"
    p4.level = 1
    p4 = tf4.add_paragraph()
    p4.text = "• Task Orchestrator & Scheduler"
    p4.level = 1
    p4 = tf4.add_paragraph()
    p4.text = "• QUIC Client + WebRTC Fallback"
    p4.level = 1
    p4 = tf4.add_paragraph()
    p4.text = "Samsung S25 (Android)"
    p4.level = 0
    p4 = tf4.add_paragraph()
    p4.text = "• QUIC Server + WebRTC Server"
    p4.level = 1
    p4 = tf4.add_paragraph()
    p4.text = "• RAM Object Store (12GB+, LRU, TTL)"
    p4.level = 1
    p4 = tf4.add_paragraph()
    p4.text = "• ML Inference Engine (ONNX Runtime + NNAPI)"
    p4.level = 1
    p4 = tf4.add_paragraph()
    p4.text = "• Job Ledger (SQLite + Rust, crash recovery)"
    p4.level = 1
    
    # Slide 5: Protocol Comparison
    slide5 = prs.slides.add_slide(prs.slide_layouts[1])
    title5 = slide5.shapes.title
    title5.text = "Protocol Comparison: QUIC vs WebRTC"
    content5 = slide5.placeholders[1]
    tf5 = content5.text_frame
    tf5.text = "QUIC (Primary)"
    p5 = tf5.add_paragraph()
    p5.text = "• Built on UDP, multiplexed streams"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "• 500+ MB/s throughput"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "• Connection migration support"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "• mTLS for security"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "WebRTC (Fallback)"
    p5.level = 0
    p5 = tf5.add_paragraph()
    p5.text = "• DataChannel for large blobs"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "• 200+ MB/s throughput"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "• Custom framing protocol"
    p5.level = 1
    p5 = tf5.add_paragraph()
    p5.text = "• Used when QUIC fails or for >10MB transfers"
    p5.level = 1
    
    # Slide 6: ML Inference Pipeline
    slide6 = prs.slides.add_slide(prs.slide_layouts[1])
    title6 = slide6.shapes.title
    title6.text = "ML Inference Pipeline on Samsung"
    content6 = slide6.placeholders[1]
    tf6 = content6.text_frame
    tf6.text = "Processing Flow"
    p6 = tf6.add_paragraph()
    p6.text = "1. Receive chunks → Reassemble in RAM"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "2. Preprocess image (normalization, resize)"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "3. Load ONNX model (cached in memory)"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "4. Run inference via NNAPI delegate"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "5. Qualcomm GPU acceleration"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "6. Post-process results"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "7. Serialize and return to iPhone"
    p6.level = 1
    p6 = tf6.add_paragraph()
    p6.text = "Performance: <100ms per image (typical model)"
    p6.level = 0
    
    # Slide 7: RAM Store Design
    slide7 = prs.slides.add_slide(prs.slide_layouts[1])
    title7 = slide7.shapes.title
    title7.text = "RAM Object Store Design"
    content7 = slide7.placeholders[1]
    tf7 = content7.text_frame
    tf7.text = "Key Features"
    p7 = tf7.add_paragraph()
    p7.text = "• 12GB+ capacity with LRU eviction"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• TTL-based expiration (default 5 minutes)"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• Variable chunk size (64KB default, up to 1MB)"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• Thread-safe with RwLock"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• Snapshot & journaling for crash recovery"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• Write-Ahead Log (WAL) for durability"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• Periodic snapshots every 30 seconds"
    p7.level = 1
    p7 = tf7.add_paragraph()
    p7.text = "• Recovery on boot: Load snapshot + replay WAL"
    p7.level = 1
    
    # Slide 8: QUIC Throughput
    slide8 = prs.slides.add_slide(prs.slide_layouts[1])
    title8 = slide8.shapes.title
    title8.text = "QUIC Throughput Assumptions"
    content8 = slide8.placeholders[1]
    tf8 = content8.text_frame
    tf8.text = "Performance Targets"
    p8 = tf8.add_paragraph()
    p8.text = "• Local WiFi: 500+ MB/s"
    p8.level = 1
    p8 = tf8.add_paragraph()
    p8.text = "• 5G Cellular: 200+ MB/s"
    p8.level = 1
    p8 = tf8.add_paragraph()
    p8.text = "• Latency: <10ms (local), <50ms (cellular)"
    p8.level = 1
    p8 = tf8.add_paragraph()
    p8.text = "• Stream multiplexing: Up to 100 concurrent streams"
    p8.level = 1
    p8 = tf8.add_paragraph()
    p8.text = "• Zero-copy where possible (JNI overhead on Android)"
    p8.level = 1
    p8 = tf8.add_paragraph()
    p8.text = "• Chunked streaming: 64KB default chunks"
    p8.level = 1
    
    # Slide 9: Battery & Performance
    slide9 = prs.slides.add_slide(prs.slide_layouts[1])
    title9 = slide9.shapes.title
    title9.text = "Battery & Performance Considerations"
    content9 = slide9.placeholders[1]
    tf9 = content9.text_frame
    tf9.text = "Battery Guard (Samsung)"
    p9 = tf9.add_paragraph()
    p9.text = "• Stop accepting jobs below 15% battery"
    p9.level = 1
    p9 = tf9.add_paragraph()
    p9.text = "• Pause inference at 12%"
    p9.level = 1
    p9 = tf9.add_paragraph()
    p9.text = "• Emergency shutdown at 10% (dump RAM to disk)"
    p9.level = 1
    p9 = tf9.add_paragraph()
    p9.text = "Performance Optimizations"
    p9.level = 0
    p9 = tf9.add_paragraph()
    p9.text = "• Thermal throttling detection and mitigation"
    p9.level = 1
    p9 = tf9.add_paragraph()
    p9.text = "• Batch inference when possible"
    p9.level = 1
    p9 = tf9.add_paragraph()
    p9.text = "• Model quantization (INT8) for speed"
    p9.level = 1
    p9 = tf9.add_paragraph()
    p9.text = "• GPU acceleration via NNAPI"
    p9.level = 1
    
    # Slide 10: Phase Roadmap
    slide10 = prs.slides.add_slide(prs.slide_layouts[1])
    title10 = slide10.shapes.title
    title10.text = "Phase Roadmap (Milestones 1-6)"
    content10 = slide10.placeholders[1]
    tf10 = content10.text_frame
    tf10.text = "Milestone 1: Core Infrastructure"
    p10 = tf10.add_paragraph()
    p10.text = "• QUIC server/client setup"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• Basic pairing via QR"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "Milestone 2: RAM Store & Ledger"
    p10.level = 0
    p10 = tf10.add_paragraph()
    p10.text = "• RAM object store implementation"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• Job ledger with SQLite"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "Milestone 3: ML Integration"
    p10.level = 0
    p10 = tf10.add_paragraph()
    p10.text = "• ONNX Runtime integration"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• NNAPI delegate configuration"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "Milestone 4: Crash Recovery"
    p10.level = 0
    p10 = tf10.add_paragraph()
    p10.text = "• Snapshot/restore mechanism"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• Job resumption logic"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "Milestone 5: Battery & Thermal"
    p10.level = 0
    p10 = tf10.add_paragraph()
    p10.text = "• Battery monitoring and guards"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• Thermal throttling detection"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "Milestone 6: Production Polish"
    p10.level = 0
    p10 = tf10.add_paragraph()
    p10.text = "• Comprehensive testing"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• Performance optimization"
    p10.level = 1
    p10 = tf10.add_paragraph()
    p10.text = "• Documentation and deployment"
    p10.level = 1
    
    # Slide 11: Risks & Mitigations
    slide11 = prs.slides.add_slide(prs.slide_layouts[1])
    title11 = slide11.shapes.title
    title11.text = "Risks & Mitigations"
    content11 = slide11.placeholders[1]
    tf11 = content11.text_frame
    tf11.text = "Risk: Network Instability"
    p11 = tf11.add_paragraph()
    p11.text = "Mitigation: WebRTC fallback, exponential backoff, connection migration"
    p11.level = 1
    p11 = tf11.add_paragraph()
    p11.text = "Risk: Device Reboot/Crash"
    p11.level = 0
    p11 = tf11.add_paragraph()
    p11.text = "Mitigation: Job ledger, RAM snapshots, WAL journaling, auto-recovery"
    p11.level = 1
    p11 = tf11.add_paragraph()
    p11.text = "Risk: Battery Depletion"
    p11.level = 0
    p11 = tf11.add_paragraph()
    p11.text = "Mitigation: Battery guards, graceful degradation, emergency checkpoints"
    p11.level = 1
    p11 = tf11.add_paragraph()
    p11.text = "Risk: Thermal Throttling"
    p11.level = 0
    p11 = tf11.add_paragraph()
    p11.text = "Mitigation: Temperature monitoring, adaptive batch sizing, task pausing"
    p11.level = 1
    p11 = tf11.add_paragraph()
    p11.text = "Risk: iOS Sandbox Limitations"
    p11.level = 0
    p11 = tf11.add_paragraph()
    p11.text = "Mitigation: App Group containers, Core Data, scoped storage APIs"
    p11.level = 1
    
    # Slide 12: Conclusion
    slide12 = prs.slides.add_slide(prs.slide_layouts[1])
    title12 = slide12.shapes.title
    title12.text = "Conclusion"
    content12 = slide12.placeholders[1]
    tf12 = content12.text_frame
    tf12.text = "Project Hydra delivers:"
    p12 = tf12.add_paragraph()
    p12.text = "✓ Production-ready distributed edge computing system"
    p12.level = 1
    p12 = tf12.add_paragraph()
    p12.text = "✓ High-performance networking (500+ MB/s QUIC)"
    p12.level = 1
    p12 = tf12.add_paragraph()
    p12.text = "✓ Robust crash recovery and job persistence"
    p12.level = 1
    p12 = tf12.add_paragraph()
    p12.text = "✓ Battery-aware scheduling and thermal management"
    p12.level = 1
    p12 = tf12.add_paragraph()
    p12.text = "✓ ML inference acceleration via ONNX Runtime + NNAPI"
    p12.level = 1
    p12 = tf12.add_paragraph()
    p12.text = "✓ Complete codebase, documentation, and deployment guides"
    p12.level = 1
    p12 = tf12.add_paragraph()
    p12.text = "Ready for deployment and extension to multi-node mesh architecture"
    p12.level = 0
    
    # Save presentation
    prs.save('hydra_architecture.pptx')
    print("Presentation saved as hydra_architecture.pptx")

if __name__ == "__main__":
    create_presentation()

