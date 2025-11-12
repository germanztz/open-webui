# CONTINUE.md - Open WebUI Project Guide

## 1. Project Overview

### Purpose
Open WebUI is an extensible, feature-rich, and user-friendly self-hosted AI platform designed to operate entirely offline. It supports various LLM runners like Ollama and OpenAI-compatible APIs, with built-in inference engine for RAG, making it a powerful AI deployment solution.

### Key Technologies
- **Frontend**: SvelteKit, TailwindCSS, TypeScript
- **Backend**: FastAPI, Python 3.11+, SQLAlchemy
- **AI Frameworks**: LangChain, Transformers, ChromaDB
- **Containerization**: Docker, Kubernetes
- **Database**: SQLite (default), PostgreSQL (optional)
- **Vector Search**: ChromaDB, Qdrant, Milvus, Pinecone (optional)

### Architecture
- **Frontend**: Built with SvelteKit, served statically from `/app/build`
- **Backend**: FastAPI server running on port 8080
- **AI Integration**: Supports Ollama, OpenAI API, and other LLM providers
- **RAG System**: Built-in document processing with embedding models
- **Extensible**: Plugin system for custom functionality

## 2. Getting Started

### Prerequisites
- Docker (recommended) or Python 3.11+
- Node.js 18+ (for development)
- GPU drivers (if using CUDA acceleration)

### Installation

#### Docker (Recommended)
```bash
# Basic installation
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

# With GPU support
docker run -d -p 3000:8080 --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:cuda

# With bundled Ollama
docker run -d -p 3000:8080 --gpus=all -v ollama:/root/.ollama -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:ollama
```

#### Python pip
```bash
pip install open-webui
open-webui serve
```

### Basic Usage
1. Access the web interface at `http://localhost:3000` (Docker) or `http://localhost:8080` (pip)
2. Configure your LLM provider (Ollama, OpenAI, etc.)
3. Start chatting with your AI models
4. Use RAG features by uploading documents or using web search

### Running Tests
```bash
# Frontend tests
npm run test:frontend

# Backend linting
npm run lint:backend

# Cypress E2E tests
npm run cy:open
```

## 3. Project Structure

```
├── backend/              # Python backend code
├── docker/               # Docker compose configurations
├── src/                  # Svelte frontend source
├── static/               # Static assets
├── test/                 # Test files
├── cypress/              # Cypress E2E tests
├── scripts/              # Helper scripts
├── docs/                 # Documentation
├── kubernetes/           # Kubernetes deployment files
├── Dockerfile            # Main Docker build file
├── docker-compose.yaml   # Docker compose configuration
├── package.json          # Frontend dependencies and scripts
├── pyproject.toml        # Backend dependencies and configuration
├── README.md             # Project documentation
└── INSTALLATION.md       # Detailed installation guide
```

## 4. Development Workflow

### Coding Standards
- **Frontend**: TypeScript, Svelte, follows ESLint and Prettier rules
- **Backend**: Python 3.11+, follows Black formatting and Pylint rules
- **Commit Messages**: Follow conventional commits format

### Testing Approach
- Unit tests for critical components
- Integration tests for API endpoints
- E2E tests with Cypress for UI flows
- Linting enforced via pre-commit hooks

### Build Process
```bash
# Frontend build
npm run build

# Development server
npm run dev

# Backend development
uvicorn open_webui.main:app --reload
```

### Deployment
- Docker containers for production
- Kubernetes manifests available in `/kubernetes/`
- Helm charts for easy deployment
- CI/CD via GitHub Actions

### Contribution Guidelines
1. Fork the repository
2. Create a feature branch
3. Write tests for new features
4. Follow coding standards
5. Submit a pull request
6. Ensure all tests pass

## 5. Key Concepts

### Domain-Specific Terms
- **RAG**: Retrieval Augmented Generation - combining document retrieval with LLM generation
- **Ollama**: Local LLM runner for running models on your machine
- **Pipelines**: Custom logic plugins for extending Open WebUI functionality
- **SCIM**: System for Cross-domain Identity Management for enterprise user provisioning

### Core Abstractions
- **Models**: LLM providers and their configurations
- **Documents**: Files processed for RAG capabilities
- **Workspaces**: User environments with saved chats and settings
- **Plugins**: Extendable functionality through Pipelines

### Design Patterns
- **Adapter Pattern**: For different LLM providers
- **Plugin Architecture**: For extensible functionality
- **Repository Pattern**: For data access layer
- **Observer Pattern**: For real-time updates via Socket.IO

## 6. Common Tasks

### Adding a New Feature
1. Create a new branch: `git checkout -b feature/my-feature`
2. Implement frontend in `src/` and backend in `backend/`
3. Add tests in `test/`
4. Update documentation if needed
5. Run linters: `npm run lint`
6. Submit pull request

### Configuring Ollama
1. Install Ollama separately or use bundled version
2. Set `OLLAMA_BASE_URL` environment variable
3. Restart Open WebUI container
4. Verify connection in Settings → Models

### Customizing Themes
1. Add CSS files to `static/themes/`
2. Reference in settings or user preferences
3. Use Tailwind classes for consistent styling

### Debugging Issues
1. Check container logs: `docker logs open-webui`
2. Enable debug mode by setting `DEBUG=true` environment variable
3. Check browser console for frontend errors
4. Review network requests in browser dev tools

## 7. Troubleshooting

### Common Issues
1. **Connection to Ollama failed**: 
   - Ensure Ollama is running
   - Check `OLLAMA_BASE_URL` setting
   - Use `--network=host` flag if needed

2. **CUDA not working**:
   - Install NVIDIA Container Toolkit
   - Use `:cuda` tagged image
   - Verify with `nvidia-smi` in container

3. **Permission denied on data directory**:
   - Ensure proper volume permissions
   - Use `-v open-webui:/app/backend/data` flag
   - Check UID/GID settings in Dockerfile

4. **RAG not working with documents**:
   - Verify embedding model is downloaded
   - Check document formats are supported
   - Ensure sufficient memory for processing

### Debugging Tips
- Use `docker exec -it open-webui /bin/bash` to enter container
- Check logs with `docker logs -f open-webui`
- Enable verbose logging by setting `LOG_LEVEL=debug`
- Use browser dev tools for frontend debugging
- Test API endpoints directly with curl or Postman

## 8. References

- [Official Documentation](https://docs.openwebui.com/)
- [GitHub Repository](https://github.com/open-webui/open-webui)
- [Discord Community](https://discord.gg/5rJgQTnV4s)
- [SvelteKit Documentation](https://kit.svelte.dev/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [LangChain Documentation](https://python.langchain.com/)
- [Ollama Documentation](https://ollama.ai/)

> ⚠️ Note: This guide is based on analysis of the project structure and key files. Some details may need verification against actual implementation.